;; ------------------------------------------------------------
;; DAO Governance Token Contract
;; Fungible Token for weighted voting
;; ------------------------------------------------------------

;; Token configuration
(define-constant contract-owner tx-sender)
(define-constant token-name "DAO Governance Token")
(define-constant token-symbol "DGOV")
(define-constant token-decimals u6)

;; Total supply: 1,000,000 tokens
(define-constant total-token-supply u1000000000000)

;; Error codes
(define-constant ERR-NOT-AUTHORIZED u401)
(define-constant ERR-INSUFFICIENT-BALANCE u402)
(define-constant ERR-INVALID-AMOUNT u403)

;; Data variables
(define-data-var token-uri (optional (string-utf8 256)) none)

;; Token balances
(define-map balances principal uint)

;; Total supply tracking
(define-data-var total-supply uint u0)

;; ------------------------------------------------------------
;; SIP-010 Functions
;; ------------------------------------------------------------

(define-public (transfer (amount uint) (sender principal) (recipient principal) (memo (optional (buff 34))))
  (begin
    (asserts! (is-eq tx-sender sender) (err ERR-NOT-AUTHORIZED))
    (asserts! (> amount u0) (err ERR-INVALID-AMOUNT))
    (try! (ft-transfer amount sender recipient))
    (print (merge { event: "transfer", amount: amount, sender: sender, recipient: recipient } 
                   { memo: memo }))
    (ok true)
  )
)

(define-read-only (get-name)
  (ok token-name)
)

(define-read-only (get-symbol)
  (ok token-symbol)
)

(define-read-only (get-decimals)
  (ok token-decimals)
)

(define-read-only (get-balance (account principal))
  (ok (default-to u0 (map-get? balances account)))
)

(define-read-only (get-total-supply)
  (ok (var-get total-supply))
)

(define-read-only (get-token-uri)
  (ok (var-get token-uri))
)

;; ------------------------------------------------------------
;; Token Management
;; ------------------------------------------------------------

(define-private (ft-transfer (amount uint) (sender principal) (recipient principal))
  (let
    (
      (sender-balance (default-to u0 (map-get? balances sender)))
      (recipient-balance (default-to u0 (map-get? balances recipient)))
    )
    (asserts! (>= sender-balance amount) (err ERR-INSUFFICIENT-BALANCE))
    (map-set balances sender (- sender-balance amount))
    (map-set balances recipient (+ recipient-balance amount))
    (ok true)
  )
)

;; Mint tokens (only contract owner)
(define-public (mint (amount uint) (recipient principal))
  (begin
    (asserts! (is-eq tx-sender contract-owner) (err ERR-NOT-AUTHORIZED))
    (asserts! (> amount u0) (err ERR-INVALID-AMOUNT))
    (let
      (
        (current-balance (default-to u0 (map-get? balances recipient)))
      )
      (map-set balances recipient (+ current-balance amount))
      (var-set total-supply (+ (var-get total-supply) amount))
      (print { event: "mint", amount: amount, recipient: recipient })
      (ok true)
    )
  )
)

;; Set token URI (only contract owner)
(define-public (set-token-uri (uri (string-utf8 256)))
  (begin
    (asserts! (is-eq tx-sender contract-owner) (err ERR-NOT-AUTHORIZED))
    (var-set token-uri (some uri))
    (ok true)
  )
)

;; Initialize total supply to contract owner
(begin
  (map-set balances contract-owner total-token-supply)
  (var-set total-supply total-token-supply)
)
