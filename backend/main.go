package main

import (
	"context"
	"fmt"
	"log"
	"net/http"
	"os"

	"firebase.google.com/go/v4"
	"github.com/go-chi/chi/v5"
	chimw "github.com/go-chi/chi/v5/middleware"
	"google.golang.org/api/option"

	"finance_backend/internal/handlers"
	mw "finance_backend/internal/middleware"
)

func main() {
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}
	jwtSecret := os.Getenv("JWT_SECRET")
	if jwtSecret == "" {
		jwtSecret = "finance_app_kuliah_rahasia_2024"
	}

	ctx := context.Background()
	opt := option.WithCredentialsFile("serviceAccountKey.json")
	app, err := firebase.NewApp(ctx, nil, opt)
	if err != nil {
		log.Fatalf("Error initializing firebase app: %v\n", err)
	}

	client, err := app.Firestore(ctx)
	if err != nil {
		log.Fatalf("Error initializing Firestore: %v\n", err)
	}
	defer client.Close()

	r := chi.NewRouter()
	r.Use(chimw.Logger)
	r.Use(chimw.Recoverer)
	r.Use(corsMiddleware)

	authH := &handlers.AuthHandler{DB: client, JWTSecret: jwtSecret}
	txH := &handlers.TransactionHandler{DB: client}

	// Public routes
	r.Post("/register", authH.Register)
	r.Post("/login", authH.Login)

	// Protected routes
	r.Group(func(r chi.Router) {
		r.Use(mw.Auth(jwtSecret))
		
		r.Get("/transactions", txH.List)
		r.Post("/transactions", txH.Create)
		r.Delete("/transactions/{id}", txH.Delete)
		r.Get("/balance", txH.GetBalance)
		r.Get("/stats", txH.GetStats)
	})

	addr := fmt.Sprintf(":%s", port)
	log.Printf("✅ Finance Backend (Firebase Firestore) berjalan di %s", addr)
	log.Fatal(http.ListenAndServe(addr, r))
}

func corsMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
		w.Header().Set("Access-Control-Allow-Headers", "Authorization, Content-Type")
		if r.Method == http.MethodOptions {
			w.WriteHeader(http.StatusNoContent)
			return
		}
		next.ServeHTTP(w, r)
	})
}
