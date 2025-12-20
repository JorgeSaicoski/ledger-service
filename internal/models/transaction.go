package models

import "time"

// Transaction represents a ledger transaction
type Transaction struct {
	ID        string    `json:"id"`
	UserID    string    `json:"user_id"`
	Amount    float64   `json:"amount"`
	Currency  string    `json:"currency"`
	Timestamp time.Time `json:"timestamp"`
}

// TransactionRequest represents the request body for creating a transaction
type TransactionRequest struct {
	UserID   string  `json:"user_id"`
	Amount   float64 `json:"amount"`
	Currency string  `json:"currency"`
}

// TransactionListResponse represents the response for listing transactions
type TransactionListResponse struct {
	Transactions []Transaction `json:"transactions"`
}

// BalanceResponse represents the balance for a single currency
type BalanceResponse struct {
	UserID   string  `json:"user_id"`
	Currency string  `json:"currency"`
	Balance  float64 `json:"balance"`
}

// AllBalancesResponse represents all balances for a user
type AllBalancesResponse struct {
	UserID   string            `json:"user_id"`
	Balances []CurrencyBalance `json:"balances"`
}

// CurrencyBalance represents a balance for a specific currency
type CurrencyBalance struct {
	Currency string  `json:"currency"`
	Balance  float64 `json:"balance"`
}

// ErrorResponse represents an error response
type ErrorResponse struct {
	Error string `json:"error"`
}

// Introduce the code here for any additional model methods or validation
