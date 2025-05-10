;; GastronomyIP - Basic platform for culinary creation registration
;; Version 1.0 - Core functionality only

;; System exception codes
(define-constant AUTH-FAILURE-ERR (err u301))
(define-constant EXISTING-ASSIGNMENT-ERR (err u302))
(define-constant RESOURCES-INSUFFICIENT-ERR (err u303))
(define-constant CREATION-UNAVAILABLE-ERR (err u304))
(define-constant COMPONENT-BOUNDARY-ERR (err u306))
(define-constant REFERENCE-MISSING-ERR (err u313))
(define-constant PROFILE-EMPTY-ERR (err u314))
(define-constant PLATFORM-CEILING-VALUE u2000000000)

;; Primary data structures
(define-map culinary-creation-vault
  { creation-id: uint }
  {
    originator: principal,
    component-quantity: uint,
    source-document: (string-ascii 30),
    taste-category: (string-ascii 20),
    availability-state: (string-ascii 20)
  }
)

(define-map resource-inventory principal uint)

(define-map artist-portfolio-tracker
  principal
  (list 5 uint)
)

;; Primary operational functions
(define-public (publish-creation (component-quantity uint) (source-document (string-ascii 30)) 
                               (taste-category (string-ascii 20)))
  (let ((creation-id (+ (var-get catalog-counter) u1)))
    ;; Input parameter validation
    (asserts! (> component-quantity u0) COMPONENT-BOUNDARY-ERR)
    (asserts! (> (len source-document) u0) REFERENCE-MISSING-ERR)
    (asserts! (> (len taste-category) u0) PROFILE-EMPTY-ERR)
    
    ;; Store the creation data
    (map-set culinary-creation-vault 
      { creation-id: creation-id }
      {
        originator: tx-sender,
        component-quantity: component-quantity,
        source-document: source-document,
        taste-category: taste-category,
        availability-state: "ACTIVE"
      }
    )
    
    ;; Update creator's portfolio
    (let 
      (
        (current-portfolio (default-to (list) (map-get? artist-portfolio-tracker tx-sender)))
        (updated-portfolio (unwrap-panic (as-max-len? (concat (list creation-id) current-portfolio) u5)))
      )
      ;; Maintain most recent 5 creations in this version
      (map-set artist-portfolio-tracker tx-sender updated-portfolio)
    )
    
    (var-set catalog-counter creation-id)
    (ok creation-id)
  )
)

(define-public (archive-creation (creation-id uint))
  (let (
    (creation-data (unwrap! (map-get? culinary-creation-vault { creation-id: creation-id }) CREATION-UNAVAILABLE-ERR))
  )
    ;; Validate ownership
    (asserts! (is-eq (get originator creation-data) tx-sender) AUTH-FAILURE-ERR)
    (asserts! (is-eq (get availability-state creation-data) "ACTIVE") CREATION-UNAVAILABLE-ERR)
    
    ;; Update availability status
    (map-set culinary-creation-vault { creation-id: creation-id } 
      (merge creation-data { availability-state: "ARCHIVED" }))
    (ok true)
  )
)

(define-public (deposit-resources (amount uint))
  (let (
    (current-balance (default-to u0 (map-get? resource-inventory tx-sender)))
  )
    ;; Validate input
    (asserts! (> amount u0) RESOURCES-INSUFFICIENT-ERR)
    (asserts! (<= (+ current-balance amount) PLATFORM-CEILING-VALUE) RESOURCES-INSUFFICIENT-ERR)
    
    ;; Update balance
    (map-set resource-inventory tx-sender (+ current-balance amount))
    (ok true)
  )
)

;; Information retrieval functions
(define-read-only (get-creation-details (creation-id uint))
  (map-get? culinary-creation-vault { creation-id: creation-id })
)

(define-read-only (check-resource-balance (entity principal))
  (default-to u0 (map-get? resource-inventory entity))
)

(define-read-only (view-portfolio (entity principal))
  (default-to (list) (map-get? artist-portfolio-tracker entity))
)

;; System state initialization
(define-data-var catalog-counter uint u0)