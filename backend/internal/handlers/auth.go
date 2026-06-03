package handlers

import (
	"context"
	"encoding/json"
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
	
	// Check if username exists
	iter := h.DB.Collection("users").Where("username", "==", req.Username).Documents(ctx)
	snaps, _ := iter.GetAll()
	if len(snaps) > 0 {
		jsonError(w, "Username sudah digunakan", http.StatusConflict)
		return
	}

	// Create new document
	docRef := h.DB.Collection("users").NewDoc()
	_, err := docRef.Set(ctx, map[string]interface{}{
		"id":            docRef.ID,
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
	json.NewEncoder(w).Encode(map[string]string{"message": "Registrasi berhasil"})
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

	id := userData["id"].(string)
	
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, jwt.MapClaims{
		"user_id": id,
		"exp":     time.Now().Add(30 * 24 * time.Hour).Unix(),
	})
	tokenStr, _ := token.SignedString([]byte(h.JWTSecret))

	jsonOK(w, map[string]interface{}{
		"token": tokenStr,
		"user": map[string]interface{}{
			"id":         id,
			"username":   userData["username"],
			"email":      userData["email"],
			"photo_url":  userData["photo_url"],
			"created_at": userData["created_at"],
		},
	})
}
