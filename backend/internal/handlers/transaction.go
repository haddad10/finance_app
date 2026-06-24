package handlers

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"sort"
	"strings"
	"time"

	"cloud.google.com/go/firestore"
	"github.com/go-chi/chi/v5"
)

type TransactionHandler struct {
	DB *firestore.Client
}

// getNextTransactionID mengambil ID numerik berurutan berikutnya untuk transaksi user tertentu
func getNextTransactionID(ctx context.Context, db *firestore.Client, userID string) (int64, error) {
	counterRef := db.Collection("counters").Doc(fmt.Sprintf("transactions_%s", userID))

	var nextID int64
	err := db.RunTransaction(ctx, func(ctx context.Context, tx *firestore.Transaction) error {
		doc, err := tx.Get(counterRef)
		if err != nil {
			// Counter belum ada, mulai dari 1
			nextID = 1
			return tx.Set(counterRef, map[string]interface{}{"count": nextID})
		}
		count, ok := doc.Data()["count"].(int64)
		if !ok {
			count = 0
		}
		nextID = count + 1
		return tx.Update(counterRef, []firestore.Update{
			{Path: "count", Value: nextID},
		})
	})
	return nextID, err
}

func (h *TransactionHandler) List(w http.ResponseWriter, r *http.Request) {
	userID := r.Context().Value("user_id").(string)
	ctx := context.Background()

	// ── Query params ──────────────────────────────────────────────────────────
	q := r.URL.Query()
	sortBy := q.Get("sort_by")
	if sortBy == "" {
		sortBy = "created_at"
	}
	sortOrder := q.Get("sort_order")
	if sortOrder == "" {
		sortOrder = "desc"
	}
	pageStr := q.Get("page")
	pageSizeStr := q.Get("page_size")
	monthStr := q.Get("month")
	yearStr := q.Get("year")

	page := 1
	pageSize := 15
	if v, err := fmt.Sscanf(pageStr, "%d", &page); v == 0 || err != nil {
		page = 1
	}
	if v, err := fmt.Sscanf(pageSizeStr, "%d", &pageSize); v == 0 || err != nil {
		pageSize = 15
	}
	if page < 1 {
		page = 1
	}
	if pageSize < 1 {
		pageSize = 15
	}

	var filterMonth, filterYear int
	fmt.Sscanf(monthStr, "%d", &filterMonth)
	fmt.Sscanf(yearStr, "%d", &filterYear)

	// ── Fetch ─────────────────────────────────────────────────────────────────
	iter := h.DB.Collection("transactions").Where("user_id", "==", userID).Documents(ctx)
	snaps, err := iter.GetAll()
	if err != nil {
		jsonError(w, "Gagal mengambil transaksi", http.StatusInternalServerError)
		return
	}

	var txs []map[string]interface{}
	for _, snap := range snaps {
		data := snap.Data()
		delete(data, "doc_key")

		// ── Filter bulan/tahun berdasarkan created_at ──────────────────────
		if filterMonth > 0 || filterYear > 0 {
			createdAtStr, _ := data["created_at"].(string)
			t, err := time.Parse(time.RFC3339, createdAtStr)
			if err != nil {
				// coba format lain
				t, err = time.Parse("2006-01-02T15:04:05Z", createdAtStr)
			}
			if err == nil {
				if filterMonth > 0 && int(t.Month()) != filterMonth {
					continue
				}
				if filterYear > 0 && t.Year() != filterYear {
					continue
				}
			}
		}

		txs = append(txs, data)
	}

	if txs == nil {
		txs = []map[string]interface{}{}
	}

	// ── Sort ──────────────────────────────────────────────────────────────────
	sort.Slice(txs, func(i, j int) bool {
		var less bool
		switch sortBy {
		case "amount":
			ai, _ := txs[i]["amount"].(float64)
			aj, _ := txs[j]["amount"].(float64)
			less = ai < aj
		default: // created_at — urutkan berdasarkan ID numerik
			idI, _ := txs[i]["id"].(int64)
			idJ, _ := txs[j]["id"].(int64)
			less = idI < idJ
		}
		if sortOrder == "asc" {
			return less
		}
		return !less
	})

	// ── Pagination ────────────────────────────────────────────────────────────
	total := len(txs)
	totalPages := (total + pageSize - 1) / pageSize
	if totalPages == 0 {
		totalPages = 1
	}

	start := (page - 1) * pageSize
	end := start + pageSize
	if start > total {
		start = total
	}
	if end > total {
		end = total
	}
	paged := txs[start:end]

	jsonOK(w, map[string]interface{}{
		"data":        paged,
		"total_pages": totalPages,
		"total":       total,
	})
}

func (h *TransactionHandler) Create(w http.ResponseWriter, r *http.Request) {
	userID := r.Context().Value("user_id").(string)

	var req struct {
		Type     string  `json:"type"`
		Amount   float64 `json:"amount"`
		Category string  `json:"category"`
		Note     string  `json:"note"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		jsonError(w, "Invalid input", http.StatusBadRequest)
		return
	}

	ctx := context.Background()

	// Dapatkan ID numerik berurutan per user (1, 2, 3, ...)
	numericID, err := getNextTransactionID(ctx, h.DB, userID)
	if err != nil {
		jsonError(w, "Gagal generate ID transaksi", http.StatusInternalServerError)
		return
	}

	// Gunakan format "userID_numericID" sebagai doc key agar unik antar user
	docKey := fmt.Sprintf("%s_%d", userID, numericID)

	data := map[string]interface{}{
		"id":         numericID,
		"user_id":    userID,
		"type":       req.Type,
		"amount":     req.Amount,
		"category":   req.Category,
		"note":       req.Note,
		"created_at": time.Now().Format(time.RFC3339),
	}

	_, err = h.DB.Collection("transactions").Doc(docKey).Set(ctx, data)
	if err != nil {
		jsonError(w, "Gagal menyimpan transaksi", http.StatusInternalServerError)
		return
	}

	jsonOK(w, data)
}

func (h *TransactionHandler) Update(w http.ResponseWriter, r *http.Request) {
	docKey := chi.URLParam(r, "id")
	userID := r.Context().Value("user_id").(string)

	// Jika docKey tidak mengandung "_", buat format "{userID}_{docKey}" (misal: "1" -> "1_1")
	if !strings.Contains(docKey, "_") {
		docKey = fmt.Sprintf("%s_%s", userID, docKey)
	}

	var req struct {
		Type     string  `json:"type"`
		Amount   float64 `json:"amount"`
		Category string  `json:"category"`
		Note     string  `json:"note"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		jsonError(w, "Invalid input", http.StatusBadRequest)
		return
	}

	ctx := context.Background()

	// Verifikasi transaksi milik user ini
	docSnap, err := h.DB.Collection("transactions").Doc(docKey).Get(ctx)
	if err != nil {
		jsonError(w, "Transaksi tidak ditemukan", http.StatusNotFound)
		return
	}
	txData := docSnap.Data()
	if txData["user_id"] != userID {
		jsonError(w, "Akses ditolak", http.StatusForbidden)
		return
	}

	_, err = h.DB.Collection("transactions").Doc(docKey).Set(ctx, map[string]interface{}{
		"type":     req.Type,
		"amount":   req.Amount,
		"category": req.Category,
		"note":     req.Note,
	}, firestore.MergeAll)
	if err != nil {
		jsonError(w, "Gagal mengupdate transaksi", http.StatusInternalServerError)
		return
	}

	// Ambil data terbaru
	updatedSnap, _ := h.DB.Collection("transactions").Doc(docKey).Get(ctx)
	data := updatedSnap.Data()
	delete(data, "doc_key")
	jsonOK(w, data)
}

func (h *TransactionHandler) Delete(w http.ResponseWriter, r *http.Request) {
	docKey := chi.URLParam(r, "id")
	userID := r.Context().Value("user_id").(string)

	// Jika docKey tidak mengandung "_", buat format "{userID}_{docKey}" (misal: "1" -> "1_1")
	if !strings.Contains(docKey, "_") {
		docKey = fmt.Sprintf("%s_%s", userID, docKey)
	}

	ctx := context.Background()

	// Verifikasi transaksi milik user ini
	docSnap, err := h.DB.Collection("transactions").Doc(docKey).Get(ctx)
	if err != nil {
		jsonError(w, "Transaksi tidak ditemukan", http.StatusNotFound)
		return
	}
	txData := docSnap.Data()
	if txData["user_id"] != userID {
		jsonError(w, "Akses ditolak", http.StatusForbidden)
		return
	}

	_, err = h.DB.Collection("transactions").Doc(docKey).Delete(ctx)
	if err != nil {
		jsonError(w, "Gagal menghapus", http.StatusInternalServerError)
		return
	}

	jsonOK(w, map[string]string{"message": "Terhapus"})
}

func (h *TransactionHandler) GetBalance(w http.ResponseWriter, r *http.Request) {
	userID := r.Context().Value("user_id").(string)
	ctx := context.Background()

	iter := h.DB.Collection("transactions").Where("user_id", "==", userID).Documents(ctx)
	snaps, err := iter.GetAll()
	if err != nil {
		jsonError(w, "Gagal mengambil data", http.StatusInternalServerError)
		return
	}

	var totalIncome, totalExpense float64
	for _, snap := range snaps {
		data := snap.Data()
		amount, _ := data["amount"].(float64)
		if data["type"] == "income" {
			totalIncome += amount
		} else {
			totalExpense += amount
		}
	}

	jsonOK(w, map[string]interface{}{
		"total_income":       totalIncome,
		"total_expense":      totalExpense,
		"balance":            totalIncome - totalExpense,
		"total_transactions": len(snaps),
	})
}

func (h *TransactionHandler) GetStats(w http.ResponseWriter, r *http.Request) {
	userID := r.Context().Value("user_id").(string)
	ctx := context.Background()

	iter := h.DB.Collection("transactions").Where("user_id", "==", userID).Documents(ctx)
	snaps, err := iter.GetAll()
	if err != nil {
		jsonError(w, "Gagal mengambil data", http.StatusInternalServerError)
		return
	}

	expenseByCategory := make(map[string]float64)
	incomeByCategory := make(map[string]float64)

	for _, snap := range snaps {
		data := snap.Data()
		amount, _ := data["amount"].(float64)
		cat, _ := data["category"].(string)

		if data["type"] == "income" {
			incomeByCategory[cat] += amount
		} else {
			expenseByCategory[cat] += amount
		}
	}

	jsonOK(w, map[string]interface{}{
		"expense_by_category": expenseByCategory,
		"incomes_by_category": incomeByCategory,
	})
}
