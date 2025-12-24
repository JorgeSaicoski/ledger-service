package repository

import (
	"context"

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
		RETURNING id, user_id, amount, currency
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
	// TODO: implement this
	return nil, nil
}

// ListByUser retrieves all transactions for a user with optional currency filter
func (r *PostgresTransactionRepository) ListByUser(ctx context.Context, userID string, currency *string, limit, offset int) ([]models.Transaction, error) {
	// TODO: implement this
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
