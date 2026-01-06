package models

import "time"

// Transaction represents a ledger transaction
type Transaction struct {
	ID        string    `json:"id"`
	UserID    string    `json:"user_id"`
	Amount    int       `json:"amount"`
	Currency  string    `json:"currency"`
	Timestamp time.Time `json:"timestamp"`
}

// TransactionRequest represents the request body for creating a transaction
type TransactionRequest struct {
	UserID   string `json:"user_id"`
	Amount   int    `json:"amount"`
	Currency string `json:"currency"`
}

// TransactionListResponse represents the response for listing transactions
type TransactionListResponse struct {
	Transactions []Transaction `json:"transactions"`
}

// ErrorResponse represents an error response
type ErrorResponse struct {
	Error string `json:"error"`
}
