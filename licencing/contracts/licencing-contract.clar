;; GastronomyIP - Intermediate platform for culinary creation registration and licensing
;; Version 2.0 - Added licensing and reputation systems

;; System exception codes
(define-constant AUTH-FAILURE-ERR (err u301))
(define-constant EXISTING-ASSIGNMENT-ERR (err u302))
(define-constant RESOURCES-INSUFFICIENT-ERR (err u303))
(define-constant CREATION-UNAVAILABLE-ERR (err u304))
(define-constant PRACTICE-INCOMPLETE-ERR (err u305))
(define-constant COMPONENT-BOUNDARY-ERR (err u306))
(define-constant FEE-STRUCTURE-ERR (err u307))
(define-constant PRACTICE-LENGTH-ERR (err u308))
(define-constant INVALID-CREATION-ID-ERR (err u309))
(define-constant COMPLEXITY-RANGE-ERR (err u310))
(define-constant RETIRED-CREATION-ERR (err u311))
(define-constant MINIMAL-RESOURCE-ERR (err u312))
(define-constant REFERENCE-MISSING-ERR (err u313))
(define-constant PROFILE-EMPTY-ERR (err u314))
(define-constant PLATFORM-CEILING-VALUE u2000000000)

;; Primary data structures
(define-map culinary-creation-vault
  { creation-id: uint }
  {
    originator: principal,
    authorized-user: (optional principal),
    component-quantity: uint,
    creator-fee-percentage: uint,
    learning-duration: uint,
    completion-block: (optional uint),
    source-document: (string-ascii 30),
    taste-category: (string-ascii 20),
    availability-state: (string-ascii 20)
  }
)

(define-map resource-inventory principal uint)

(define-map creator-acclaim-registry principal uint)

(define-map artist-portfolio-tracker
  principal
  (list 7 uint)
)

;; Primary operational functions
(define-public (publish-creation (component-quantity uint) (creator-fee-percentage uint) (learning-duration uint) 
                               (source-document (string-ascii 30)) (taste-category (string-ascii 20)))
  (let ((creation-id (+ (var-get catalog-counter) u1)))
    ;; Input parameter validation
    (asserts! (> component-quantity u0) COMPONENT-BOUNDARY-ERR)
    (asserts! (<= creator-fee-percentage u50) FEE-STRUCTURE-ERR)
    (asserts! (and (> learning-duration u0) (<= learning-duration u10000)) PRACTICE-LENGTH-ERR)
    (asserts! (> (len source-document) u0) REFERENCE-MISSING-ERR)
    (asserts! (> (len taste-category) u0) PROFILE-EMPTY-ERR)
    
    ;; Store the creation data
    (map-set culinary-creation-vault 
      { creation-id: creation-id }
      {
        originator: tx-sender,
        authorized-user: none,
        component-quantity: component-quantity,
        creator-fee-percentage: creator-fee-percentage,
        learning-duration: learning-duration,
        completion-block: none,
        source-document: source-document,
        taste-category: taste-category,
        availability-state: "ACTIVE"
      }
    )
    
    ;; Update creator's portfolio
    (let 
      (
        (current-portfolio (default-to (list) (map-get? artist-portfolio-tracker tx-sender)))
        (updated-portfolio (unwrap-panic (as-max-len? (concat (list creation-id) current-portfolio) u7)))
      )
      ;; Maintain most recent 7 creations in this version
      (map-set artist-portfolio-tracker tx-sender updated-portfolio)
    )
    
    (var-set catalog-counter creation-id)
    (ok creation-id)
  )
)

(define-public (acquire-rights (creation-id uint))
  (let (
    (creation-data (unwrap! (map-get? culinary-creation-vault { creation-id: creation-id }) CREATION-UNAVAILABLE-ERR))
    (student-resources (default-to u0 (map-get? resource-inventory tx-sender)))
  )
    ;; Validate transaction conditions
    (asserts! (<= creation-id (var-get catalog-counter)) INVALID-CREATION-ID-ERR)
    (asserts! (is-none (get authorized-user creation-data)) EXISTING-ASSIGNMENT-ERR)
    (asserts! (is-eq (get availability-state creation-data) "ACTIVE") CREATION-UNAVAILABLE-ERR)
    (asserts! (>= student-resources (get component-quantity creation-data)) RESOURCES-INSUFFICIENT-ERR)
    
    ;; Update licensing records
    (map-set culinary-creation-vault { creation-id: creation-id }
      (merge creation-data { 
        authorized-user: (some tx-sender),
        completion-block: (some block-height),
        availability-state: "LEARNING"
      })
    )
    
    ;; Process resource transfer
    (map-set resource-inventory tx-sender (- student-resources (get component-quantity creation-data)))
    (map-set resource-inventory (get originator creation-data) 
      (+ (default-to u0 (map-get? resource-inventory (get originator creation-data))) (get component-quantity creation-data)))
    
    (ok true)
  )
)

(define-public (validate-proficiency (creation-id uint))
  (let (
    (creation-data (unwrap! (map-get? culinary-creation-vault { creation-id: creation-id }) CREATION-UNAVAILABLE-ERR))
    (student-resources (default-to u0 (map-get? resource-inventory tx-sender)))
    (base-cost (get component-quantity creation-data))
    (royalty-amount (/ (* (get component-quantity creation-data) (get creator-fee-percentage creation-data)) u100))
    (certification-fee (+ base-cost royalty-amount))
  )
    ;; Validate operation conditions
    (asserts! (<= creation-id (var-get catalog-counter)) INVALID-CREATION-ID-ERR)
    (asserts! (is-eq (get authorized-user creation-data) (some tx-sender)) AUTH-FAILURE-ERR)
    (asserts! (is-eq (get availability-state creation-data) "LEARNING") CREATION-UNAVAILABLE-ERR)
    (asserts! (>= (- block-height (unwrap! (get completion-block creation-data) CREATION-UNAVAILABLE-ERR)) 
                (get learning-duration creation-data)) PRACTICE-INCOMPLETE-ERR)
    (asserts! (>= student-resources certification-fee) RESOURCES-INSUFFICIENT-ERR)
    
    ;; Execute fee collection
    (map-set resource-inventory tx-sender (- student-resources certification-fee))
    (map-set resource-inventory (get originator creation-data) 
      (+ (default-to u0 (map-get? resource-inventory (get originator creation-data))) 
         certification-fee)
    )
    
    ;; Update creator's reputation
    (let ((acclaim-points (default-to u0 (map-get? creator-acclaim-registry 
                        (get originator creation-data)))))
      (map-set creator-acclaim-registry
        (get originator creation-data)
        (+ acclaim-points u1)
      )
    )
    
    ;; Update creation status
    (map-set culinary-creation-vault { creation-id: creation-id } 
      (merge creation-data { availability-state: "CERTIFIED" }))
    (ok true)
  )
)

(define-public (archive-creation (creation-id uint))
  (let (
    (creation-data (unwrap! (map-get? culinary-creation-vault { creation-id: creation-id }) CREATION-UNAVAILABLE-ERR))
  )
    ;; Validate ownership
    (asserts! (<= creation-id (var-get catalog-counter)) INVALID-CREATION-ID-ERR)
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
    (asserts! (> amount u0) MINIMAL-RESOURCE-ERR)
    (asserts! (<= amount PLATFORM-CEILING-VALUE) MINIMAL-RESOURCE-ERR)
    (asserts! (<= (+ current-balance amount) PLATFORM-CEILING-VALUE) MINIMAL-RESOURCE-ERR)
    
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

(define-read-only (get-creator-reputation (artist principal))
  (default-to u0 (map-get? creator-acclaim-registry artist))
)

(define-read-only (view-portfolio (entity principal))
  (default-to (list) (map-get? artist-portfolio-tracker entity))
)

;; System state initialization
(define-data-var catalog-counter uint u0)