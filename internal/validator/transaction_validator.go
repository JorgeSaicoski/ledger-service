package validator

import (
	"errors"
	"regexp"

	"github.com/JorgeSaicoski/ledger-service/internal/models"
)

var (
	// ErrUserIDEmpty indicates user_id is empty
	ErrUserIDEmpty = errors.New("user_id cannot be empty")
	// ErrCurrencyEmpty indicates currency is empty
	ErrCurrencyEmpty = errors.New("currency cannot be empty")
	// ErrCurrencyInvalid indicates currency format is invalid
	ErrCurrencyInvalid = errors.New("currency must be alphanumeric and max 32 characters")
	// ErrUserIDInvalid indicates user_id format is invalid
	ErrUserIDInvalid = errors.New("user_id must be a valid UUID")
	// ErrUUIDInvalid indicates UUID format is invalid
	ErrUUIDInvalid = errors.New("invalid UUID format")
)

// TransactionValidator handles validation of transaction data
type TransactionValidator struct {
	currencyRegex *regexp.Regexp
	uuidRegex     *regexp.Regexp
}

// NewTransactionValidator creates a new validator instance
func NewTransactionValidator() *TransactionValidator {
	return &TransactionValidator{
		currencyRegex: regexp.MustCompile(`^[a-z0-9_]+$`),
		uuidRegex:     regexp.MustCompile(`^[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$`)}
}

// ValidateTransactionRequest validates a transaction creation request
func (v *TransactionValidator) ValidateTransactionRequest(req models.TransactionRequest) error {
	if err := v.validateUserID(req.UserID); err != nil {
		return err
	}
	if err := v.validateCurrency(req.Currency); err != nil {
		return err
	}
	return nil
}

// validateUserID validates user_id format
func (v *TransactionValidator) validateUserID(userID string) error {
	if len(userID) == 0 {
		return ErrUserIDEmpty
	}
	if err := v.ValidateUUID(userID); err != nil {
		return ErrUserIDInvalid
	}
	return nil
}

// ValidateCurrency validates currency format
func (v *TransactionValidator) validateCurrency(currency string) error {
	if currency == "" {
		return ErrCurrencyEmpty
	}
	if len(currency) > 32 {
		return ErrCurrencyInvalid
	}
	if !v.currencyRegex.MatchString(currency) {
		return ErrCurrencyInvalid
	}
	return nil
}

// ValidateUUID validates UUID format
func (v *TransactionValidator) ValidateUUID(id string) error {
	if !v.uuidRegex.MatchString(id) {
		return ErrUUIDInvalid
	}
	return nil
}
