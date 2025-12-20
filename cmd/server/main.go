package main

import (
	"fmt"
	"log"
	"net/http"
	"os"

	"github.com/gorilla/mux"
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

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	router := mux.NewRouter()

	// TODO: Add routes here
	// router.HandleFunc("/transactions", handler.CreateTransaction).Methods("POST")
	// router.HandleFunc("/transactions/{id}", handler.GetTransaction).Methods("GET")
	// router.HandleFunc("/transactions", handler.ListTransactions).Methods("GET")
	// router.HandleFunc("/balance", handler.GetBalance).Methods("GET")

	log.Printf("Starting server on port %s", port)
	log.Fatal(http.ListenAndServe(":"+port, router))
}
