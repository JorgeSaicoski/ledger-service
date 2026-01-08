package main

import (
	"context"
	"fmt"
	"log"
	"net/http"
	"os"

	"github.com/bardockgaucho/ledger-service/internal/handlers"
	"github.com/bardockgaucho/ledger-service/internal/repository"
	"github.com/bardockgaucho/ledger-service/internal/validator"
	"github.com/jackc/pgx/v5/pgxpool"
)

func main() {
	ctx := context.Background()

	// Database setup
	dbURL := os.Getenv("DATABASE_URL")
	if dbURL == "" {
		fmt.Println("DATABASE_URL environment variable is not set")
		os.Exit(1)
	}

	pool, err := pgxpool.New(ctx, dbURL)
	if err != nil {
		fmt.Printf("unable to connect to database: %v\n", err)
		os.Exit(1)
	}
	defer pool.Close()

	// Initialize our application layers
	// Repository: handles database operations
	repo := repository.NewPostgresTransactionRepository(pool)

	// Validator: handles input validation
	val := validator.NewTransactionValidator()

	// Handler: handles HTTP requests and responses
	handler := handlers.NewTransactionHandler(repo, val)

	// Get port from environment
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	// === HTTP SERVER SETUP ===
	// We use http.NewServeMux() which is Go's built-in HTTP request multiplexer (router)
	// A "mux" (multiplexer) is a component that routes incoming HTTP requests to the
	// appropriate handler function based on the request's URL path and HTTP method.
	//
	// Think of it like a switchboard operator who receives calls (HTTP requests) and
	// connects them to the right person (handler function).
	mux := http.NewServeMux()

	// === ROUTE REGISTRATION ===
	// Go 1.22+ introduced a new pattern syntax: "METHOD /path"
	// This allows us to specify both the HTTP method and path in one string.

	// Route 1: Create a new transaction
	// Pattern: "POST /transactions" means only POST requests to /transactions will match
	// Handler: handler.CreateTransaction is called when this route matches
	mux.HandleFunc("POST /transactions", handler.CreateTransaction)

	// Route 2 & 3: Get transaction OR List transactions (same path, different query params)
	// Pattern: "GET /transactions" matches all GET requests to /transactions
	// We use a wrapper function to distinguish between two use cases:
	//   - If "id" query param exists -> GetTransaction (single transaction)
	//   - Otherwise -> ListTransactions (list with filters)
	mux.HandleFunc("GET /transactions", func(w http.ResponseWriter, r *http.Request) {
		// r.URL.Query() returns all query parameters as a map
		// r.URL.Query().Has("id") checks if the "id" parameter exists
		if r.URL.Query().Has("id") {
			// GET /transactions?id=123 -> GetTransaction
			handler.GetTransaction(w, r)
		} else {
			// GET /transactions?user_id=abc&currency=USD -> ListTransactions
			handler.ListTransactions(w, r)
		}
	})

	// === HTTP HANDLER SIGNATURE ===
	// Every HTTP handler in Go has this signature:
	// func(w http.ResponseWriter, r *http.Request)
	//
	// - w (ResponseWriter): Used to write the HTTP response back to the client
	//   Methods: w.Write(), w.WriteHeader(), w.Header()
	//
	// - r (Request): Contains all information about the incoming HTTP request
	//   Fields: r.Method, r.URL, r.Header, r.Body, r.Context()

	// === START THE SERVER ===
	// http.ListenAndServe does two things:
	// 1. Opens a TCP socket on the specified address (":8080" means localhost:8080)
	// 2. Listens for incoming HTTP connections and routes them through our mux
	//
	// The second parameter is the handler - our mux that we configured above.
	// This is a blocking call - it runs until the program is terminated or an error occurs.
	addr := ":" + port
	log.Printf("Starting server on %s", addr)
	log.Println("Available endpoints:")
	log.Println("  POST   /transactions                    - Create a new transaction")
	log.Println("  GET    /transactions?id=<uuid>          - Get transaction by ID")
	log.Println("  GET    /transactions?user_id=<uuid>     - List user transactions")

	if err := http.ListenAndServe(addr, mux); err != nil {
		log.Fatalf("Server failed to start: %v", err)
	}
}
