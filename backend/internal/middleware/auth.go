package middleware

import (
	"context"
	"net/http"
	"strings"

	"github.com/golang-jwt/jwt/v5"
)

func Auth(jwtSecret string) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			// Shortcut untuk testing di Postman menggunakan User ID langsung
			xUserID := r.Header.Get("X-User-ID")
			if xUserID != "" {
				ctx := context.WithValue(r.Context(), "user_id", xUserID)
				next.ServeHTTP(w, r.WithContext(ctx))
				return
			}

			authHeader := r.Header.Get("Authorization")
			if authHeader == "" {
				http.Error(w, "Missing token", http.StatusUnauthorized)
				return
			}
			parts := strings.Split(authHeader, " ")
			if len(parts) != 2 || parts[0] != "Bearer" {
				http.Error(w, "Invalid token format", http.StatusUnauthorized)
				return
			}
			tokenStr := parts[1]

			token, err := jwt.Parse(tokenStr, func(token *jwt.Token) (interface{}, error) {
				return []byte(jwtSecret), nil
			})

			if err != nil || !token.Valid {
				http.Error(w, "Invalid token", http.StatusUnauthorized)
				return
			}

			claims, ok := token.Claims.(jwt.MapClaims)
			if !ok {
				http.Error(w, "Invalid claims", http.StatusUnauthorized)
				return
			}

			userID, _ := claims["user_id"].(string)
			ctx := context.WithValue(r.Context(), "user_id", userID)
			next.ServeHTTP(w, r.WithContext(ctx))
		})
	}
}
