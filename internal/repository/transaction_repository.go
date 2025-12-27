package repository

import (
	"context"
	"fmt"

	"github.com/bardockgaucho/ledger-service/internal/models"
	"github.com/jackc/pgx/v5/pgxpool"
)

// TransactionRepository defines the interface for transaction data operations
type TransactionRepository interface {
	Create(ctx context.Context, req models.TransactionRequest) (*models.Transaction, error)
	GetByID(ctx context.Context, id string) (*models.Transaction, error)
	ListByUser(ctx context.Context, userID string, currency *string, limit, offset int) ([]models.Transaction, error)
	GetBalance(ctx context.Context, userID, currency string) (int, error)
	GetAllBalances(ctx context.Context, userID string) ([]models.CurrencyBalance, error)
}

// PostgresTransactionRepository implements TransactionRepository using PostgreSQL
type PostgresTransactionRepository struct {
	db *pgxpool.Pool
}

// NewPostgresTransactionRepository creates a new PostgreSQL repository
func NewPostgresTransactionRepository(db *pgxpool.Pool) *PostgresTransactionRepository {
	return &PostgresTransactionRepository{db: db}
}

// Create creates a new transaction in the database
func (r *PostgresTransactionRepository) Create(ctx context.Context, req models.TransactionRequest) (string, error) {
	query := `
		INSERT INTO transactions (user_id, amount, currency) 
		VALUES ($1, $2, $3) 
		RETURNING id
	`
	var id string
	err := r.db.QueryRow(ctx, query, req.UserID, req.Amount, req.Currency).Scan(&id)
	if err != nil {
		return "error", err
	}
	return id, nil
}

// GetByID retrieves a transaction by its ID
func (r *PostgresTransactionRepository) GetByID(ctx context.Context, id string) (*models.Transaction, error) {
	query := `
		SELECT id, user_id, amount, currency, timestamp 
		FROM transactions
		WHERE id = $1
	`
	var transaction models.Transaction
	err := r.db.QueryRow(ctx, query, id).Scan(&transaction.ID, &transaction.UserID, &transaction.Amount, &transaction.Currency, &transaction.Timestamp)
	if err != nil {
		return nil, err
	}
	return &transaction, nil
}

// ListByUser retrieves all transactions for a user with optional currency filter
func (r *PostgresTransactionRepository) ListByUser(ctx context.Context, userID string, currency *string, limit, offset int) ([]models.Transaction, error) {
	if currency != nil || limit == 0 {
		return nil, fmt.Errorf("filter not implemented")
	}
	query := `
		SELECT id, user_id, amount, currency, timestamp 
		FROM transactions
		WHERE user_id = $1
		ORDER BY timestamp DESC
		LIMIT $2 OFFSET $3
	`
	var transactions []models.Transaction
	err := r.db.QueryRow(ctx, query, userID, limit, offset).Scan(&transactions)
	if err != nil {
		return nil, err
	}

	return []models.Transaction{}, nil
}

// GetBalance calculates the balance for a user in a specific currency
func (r *PostgresTransactionRepository) GetBalance(ctx context.Context, userID, currency string) (int, error) {
	// TODO: implement this
	return 0, nil
}

// GetAllBalances calculates balances for a user across all currencies
func (r *PostgresTransactionRepository) GetAllBalances(ctx context.Context, userID string) ([]models.CurrencyBalance, error) {
	// TODO: implement this
	return []models.CurrencyBalance{}, nil
}
