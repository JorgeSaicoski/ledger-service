package main

import (
	"context"
	"fmt"
	"os"

	"github.com/JorgeSaicoski/ledger-service/internal/repository"
	"github.com/jackc/pgx/v5/pgxpool"
)

func main() {
	ctx := context.Background()

	dbURL := os.Getenv("DATABASE_URL")
	if dbURL == "" {
		fmt.Println("DATABASE_URL environment variable is not set")
		os.Exit(1)
	}

	pool, err := pgxpool.New(ctx, dbURL)
	if err != nil {
		fmt.Printf("unable to connect to database: %v", err)
		os.Exit(1)
	}
	defer pool.Close()
	repo := repository.NewPostgresTransactionRepository(pool)
	_ = repo // to avoid unused variable error, remove when repo is used

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
