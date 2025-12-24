package main

import (
	"fmt"
	"os"

	"github.com/bardockgaucho/ledger-service/internal/repository"
	"github.com/jackc/pgx/v5/pgxpool"
)

func main() {
	// TODO: implement this
	// 1. Set up database connection
	// 2. Initialize repository
	// 3. Initialize validator
	// 4. Initialize handlers
	// 5. Set up routes
	// 6. Add middleware
	// 7. Start server
	ctx := os.Background()

	pool, err := pgxpool.Connect(ctx, os.Getenv("DATABASE_URL"))
	if err != nil {
		fmt.Println("unable to connect to database:")
		panic(err)
	}
	repository.NewPostgresTransactionRepository(pool)

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	// TODO: Add routes here
	// router.HandleFunc("/transactions", handler.CreateTransaction).Methods("POST")
	// router.HandleFunc("/transactions/{id}", handler.GetTransaction).Methods("GET")
	// router.HandleFunc("/transactions", handler.ListTransactions).Methods("GET")
	// router.HandleFunc("/balance", handler.GetBalance).Methods("GET")

}
