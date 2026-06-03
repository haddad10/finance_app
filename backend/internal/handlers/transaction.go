package handlers

import (
	"context"
	"encoding/json"
	"net/http"
	"time"

	"cloud.google.com/go/firestore"
	"github.com/go-chi/chi/v5"
)

type TransactionHandler struct {
	DB *firestore.Client
}

func (h *TransactionHandler) List(w http.ResponseWriter, r *http.Request) {
	userID := r.Context().Value("user_id").(string)
	ctx := context.Background()
	
	iter := h.DB.Collection("transactions").Where("user_id", "==", userID).Documents(ctx)
	snaps, err := iter.GetAll()
	if err != nil {
		jsonError(w, "Gagal mengambil transaksi", http.StatusInternalServerError)
		return
	}
	
	var txs []map[string]interface{}
	for _, snap := range snaps {
		txs = append(txs, snap.Data())
	}
	
	if txs == nil {
		txs = []map[string]interface{}{}
	}

	jsonOK(w, map[string]interface{}{
		"data": txs,
		"total_pages": 1,
		"total": len(txs),
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
	docRef := h.DB.Collection("transactions").NewDoc()
	
	data := map[string]interface{}{
		"id":         docRef.ID,
		"user_id":    userID,
		"type":       req.Type,
		"amount":     req.Amount,
		"category":   req.Category,
		"note":       req.Note,
		"created_at": time.Now().Format(time.RFC3339),
	}
	
	_, err := docRef.Set(ctx, data)
	if err != nil {
		jsonError(w, "Gagal menyimpan transaksi", http.StatusInternalServerError)
		return
	}

	jsonOK(w, data)
}

func (h *TransactionHandler) Delete(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")
	ctx := context.Background()
	
	_, err := h.DB.Collection("transactions").Doc(id).Delete(ctx)
	if err != nil {
		jsonError(w, "Gagal menghapus", http.StatusInternalServerError)
		return
	}
	
	jsonOK(w, map[string]string{"message": "Terhapus"})
}

// Stubs for balance and stats
func (h *TransactionHandler) GetBalance(w http.ResponseWriter, r *http.Request) {
	jsonOK(w, map[string]interface{}{
		"total_income": 0,
		"total_expense": 0,
		"current_balance": 0,
	})
}

func (h *TransactionHandler) GetStats(w http.ResponseWriter, r *http.Request) {
	jsonOK(w, map[string]interface{}{
		"by_category": []interface{}{},
		"monthly": []interface{}{},
	})
}
