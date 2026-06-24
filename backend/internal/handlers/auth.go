package handlers

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"strings"
	"time"

	"cloud.google.com/go/firestore"
	"github.com/golang-jwt/jwt/v5"
	"golang.org/x/crypto/bcrypt"
)

type AuthHandler struct {
	DB        *firestore.Client
	JWTSecret string
}

func jsonError(w http.ResponseWriter, msg string, code int) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(code)
	json.NewEncoder(w).Encode(map[string]string{"error": msg})
}

func jsonOK(w http.ResponseWriter, data interface{}) {
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(data)
}

// getNextUserID mengambil ID numerik berurutan berikutnya untuk akun baru (1, 2, 3, ...)
func getNextUserID(ctx context.Context, db *firestore.Client) (int64, error) {
	counterRef := db.Collection("counters").Doc("users")

	var nextID int64
	err := db.RunTransaction(ctx, func(ctx context.Context, tx *firestore.Transaction) error {
		doc, err := tx.Get(counterRef)
		if err != nil {
			// Dokumen counter belum ada, mulai dari 1
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

func (h *AuthHandler) Register(w http.ResponseWriter, r *http.Request) {
	var req struct {
		Username string `json:"username"`
		Email    string `json:"email"`
		Password string `json:"password"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		jsonError(w, "Format request tidak valid", http.StatusBadRequest)
		return
	}

	req.Username = strings.TrimSpace(req.Username)
	req.Email = strings.TrimSpace(req.Email)

	if req.Username == "" || req.Email == "" || req.Password == "" {
		jsonError(w, "Username, email, dan password wajib diisi", http.StatusBadRequest)
		return
	}

	hash, _ := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)

	ctx := context.Background()

	// Cek apakah username sudah digunakan
	iter := h.DB.Collection("users").Where("username", "==", req.Username).Documents(ctx)
	snaps, _ := iter.GetAll()
	if len(snaps) > 0 {
		jsonError(w, "Username sudah digunakan", http.StatusConflict)
		return
	}

	// Dapatkan ID numerik berurutan (1, 2, 3, ...)
	numericID, err := getNextUserID(ctx, h.DB)
	if err != nil {
		jsonError(w, "Gagal generate ID akun", http.StatusInternalServerError)
		return
	}

	// Simpan dokumen dengan key berupa string dari ID numerik
	docKey := fmt.Sprintf("%d", numericID)
	_, err = h.DB.Collection("users").Doc(docKey).Set(ctx, map[string]interface{}{
		"id":            numericID,
		"username":      req.Username,
		"email":         req.Email,
		"password_hash": string(hash),
		"photo_url":     "",
		"created_at":    time.Now().Format(time.RFC3339),
	})

	if err != nil {
		jsonError(w, "Gagal mendaftar, coba lagi", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(map[string]interface{}{
		"message": "Registrasi berhasil",
		"id":      numericID,
	})
}

func (h *AuthHandler) Login(w http.ResponseWriter, r *http.Request) {
	var req struct {
		Username string `json:"username"`
		Password string `json:"password"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		jsonError(w, "Format request tidak valid", http.StatusBadRequest)
		return
	}

	ctx := context.Background()
	iter := h.DB.Collection("users").Where("username", "==", strings.TrimSpace(req.Username)).Documents(ctx)
	snaps, err := iter.GetAll()

	if err != nil || len(snaps) == 0 {
		jsonError(w, "Username atau password salah", http.StatusUnauthorized)
		return
	}

	userData := snaps[0].Data()
	passwordHash := userData["password_hash"].(string)

	if err := bcrypt.CompareHashAndPassword([]byte(passwordHash), []byte(req.Password)); err != nil {
		jsonError(w, "Username atau password salah", http.StatusUnauthorized)
		return
	}

	// ID bisa int64 (akun baru) atau string (akun lama) — handle keduanya
	var userIDStr string
	switch v := userData["id"].(type) {
	case int64:
		userIDStr = fmt.Sprintf("%d", v)
	case string:
		userIDStr = v
	default:
		userIDStr = fmt.Sprintf("%v", v)
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, jwt.MapClaims{
		"user_id": userIDStr,
		"exp":     time.Now().Add(30 * 24 * time.Hour).Unix(),
	})
	tokenStr, _ := token.SignedString([]byte(h.JWTSecret))

	jsonOK(w, map[string]interface{}{
		"token": tokenStr,
		"user": map[string]interface{}{
			"id":         userData["id"],
			"username":   userData["username"],
			"email":      userData["email"],
			"photo_url":  userData["photo_url"],
			"created_at": userData["created_at"],
		},
	})
}
