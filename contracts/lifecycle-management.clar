;; Lifecycle Management Contract
;; Manages complete asset lifecycle from creation to disposal

;; Error constants
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-INVALID-INPUT (err u101))
(define-constant ERR-NOT-FOUND (err u102))
(define-constant ERR-ALREADY-EXISTS (err u103))
(define-constant ERR-INVALID-STATUS (err u104))

;; Asset lifecycle stages
(define-constant STAGE-CREATED "created")
(define-constant STAGE-ACTIVE "active")
(define-constant STAGE-MAINTENANCE "maintenance")
(define-constant STAGE-RETIRED "retired")
(define-constant STAGE-DISPOSED "disposed")

;; Asset registry
(define-map assets
  { asset-id: uint }
  {
    name: (string-ascii 100),
    category: (string-ascii 50),
    serial-number: (string-ascii 100),
    manufacturer: (string-ascii 100),
    model: (string-ascii 100),
    purchase-date: uint,
    purchase-cost: uint,
    current-owner: (string-ascii 50),
    lifecycle-stage: (string-ascii 20),
    created-by: (string-ascii 50),
    created-at: uint
  }
)

;; Asset ownership history
(define-map ownership-history
  { asset-id: uint, transfer-id: uint }
  {
    previous-owner: (string-ascii 50),
    new-owner: (string-ascii 50),
    transfer-date: uint,
    transfer-reason: (string-ascii 100),
    authorized-by: (string-ascii 50)
  }
)

;; Asset lifecycle events
(define-map lifecycle-events
  { asset-id: uint, event-id: uint }
  {
    event-type: (string-ascii 50),
    from-stage: (string-ascii 20),
    to-stage: (string-ascii 20),
    timestamp: uint,
    triggered-by: (string-ascii 50),
    notes: (optional (string-ascii 200))
  }
)

;; Counters
(define-data-var next-asset-id uint u1)
(define-map asset-transfer-counter { asset-id: uint } { count: uint })
(define-map asset-event-counter { asset-id: uint } { count: uint })

;; Create new asset
(define-public (create-asset
  (name (string-ascii 100))
  (category (string-ascii 50))
  (serial-number (string-ascii 100))
  (manufacturer (string-ascii 100))
  (model (string-ascii 100))
  (purchase-date uint)
  (purchase-cost uint)
  (owner (string-ascii 50))
  (coordinator-id (string-ascii 50)))
  (let ((asset-id (var-get next-asset-id)))
    (asserts! (> (len name) u0) ERR-INVALID-INPUT)
    (asserts! (> (len serial-number) u0) ERR-INVALID-INPUT)
    (asserts! (> purchase-cost u0) ERR-INVALID-INPUT)
    (asserts! (> (len coordinator-id) u0) ERR-INVALID-INPUT)

    ;; Create asset record
    (map-set assets
      { asset-id: asset-id }
      {
        name: name,
        category: category,
        serial-number: serial-number,
        manufacturer: manufacturer,
        model: model,
        purchase-date: purchase-date,
        purchase-cost: purchase-cost,
        current-owner: owner,
        lifecycle-stage: STAGE-CREATED,
        created-by: coordinator-id,
        created-at: block-height
      }
    )

    ;; Record creation event
    (unwrap-panic (record-lifecycle-event asset-id "asset-creation" "" STAGE-CREATED coordinator-id none))

    (var-set next-asset-id (+ asset-id u1))
    (ok asset-id)
  )
)

;; Activate asset
(define-public (activate-asset (asset-id uint) (coordinator-id (string-ascii 50)))
  (let ((asset (unwrap! (map-get? assets { asset-id: asset-id }) ERR-NOT-FOUND)))
    (asserts! (> (len coordinator-id) u0) ERR-INVALID-INPUT)
    (asserts! (is-eq (get lifecycle-stage asset) STAGE-CREATED) ERR-INVALID-STATUS)

    (map-set assets
      { asset-id: asset-id }
      (merge asset { lifecycle-stage: STAGE-ACTIVE })
    )

    (unwrap-panic (record-lifecycle-event asset-id "activation" STAGE-CREATED STAGE-ACTIVE coordinator-id none))
    (ok true)
  )
)

;; Transfer asset ownership
(define-public (transfer-ownership
  (asset-id uint)
  (new-owner (string-ascii 50))
  (transfer-reason (string-ascii 100))
  (coordinator-id (string-ascii 50)))
  (let (
    (asset (unwrap! (map-get? assets { asset-id: asset-id }) ERR-NOT-FOUND))
    (current-count (default-to u0 (get count (map-get? asset-transfer-counter { asset-id: asset-id }))))
    (new-count (+ current-count u1))
  )
    (asserts! (> (len new-owner) u0) ERR-INVALID-INPUT)
    (asserts! (> (len coordinator-id) u0) ERR-INVALID-INPUT)
    (asserts! (not (is-eq (get lifecycle-stage asset) STAGE-DISPOSED)) ERR-INVALID-STATUS)

    ;; Record ownership transfer
    (map-set ownership-history
      { asset-id: asset-id, transfer-id: new-count }
      {
        previous-owner: (get current-owner asset),
        new-owner: new-owner,
        transfer-date: block-height,
        transfer-reason: transfer-reason,
        authorized-by: coordinator-id
      }
    )

    ;; Update asset owner
    (map-set assets
      { asset-id: asset-id }
      (merge asset { current-owner: new-owner })
    )

    ;; Update transfer counter
    (map-set asset-transfer-counter
      { asset-id: asset-id }
      { count: new-count }
    )

    (unwrap-panic (record-lifecycle-event asset-id "ownership-transfer" (get lifecycle-stage asset) (get lifecycle-stage asset) coordinator-id (some transfer-reason)))
    (ok new-count)
  )
)

;; Retire asset
(define-public (retire-asset (asset-id uint) (coordinator-id (string-ascii 50)) (notes (optional (string-ascii 200))))
  (let ((asset (unwrap! (map-get? assets { asset-id: asset-id }) ERR-NOT-FOUND)))
    (asserts! (> (len coordinator-id) u0) ERR-INVALID-INPUT)
    (asserts! (is-eq (get lifecycle-stage asset) STAGE-ACTIVE) ERR-INVALID-STATUS)

    (map-set assets
      { asset-id: asset-id }
      (merge asset { lifecycle-stage: STAGE-RETIRED })
    )

    (unwrap-panic (record-lifecycle-event asset-id "retirement" STAGE-ACTIVE STAGE-RETIRED coordinator-id notes))
    (ok true)
  )
)

;; Dispose asset
(define-public (dispose-asset (asset-id uint) (coordinator-id (string-ascii 50)) (notes (optional (string-ascii 200))))
  (let ((asset (unwrap! (map-get? assets { asset-id: asset-id }) ERR-NOT-FOUND)))
    (asserts! (> (len coordinator-id) u0) ERR-INVALID-INPUT)
    (asserts! (is-eq (get lifecycle-stage asset) STAGE-RETIRED) ERR-INVALID-STATUS)

    (map-set assets
      { asset-id: asset-id }
      (merge asset { lifecycle-stage: STAGE-DISPOSED })
    )

    (unwrap-panic (record-lifecycle-event asset-id "disposal" STAGE-RETIRED STAGE-DISPOSED coordinator-id notes))
    (ok true)
  )
)

;; Record lifecycle event
(define-private (record-lifecycle-event
  (asset-id uint)
  (event-type (string-ascii 50))
  (from-stage (string-ascii 20))
  (to-stage (string-ascii 20))
  (coordinator-id (string-ascii 50))
  (notes (optional (string-ascii 200))))
  (let (
    (current-count (default-to u0 (get count (map-get? asset-event-counter { asset-id: asset-id }))))
    (new-count (+ current-count u1))
  )
    (map-set lifecycle-events
      { asset-id: asset-id, event-id: new-count }
      {
        event-type: event-type,
        from-stage: from-stage,
        to-stage: to-stage,
        timestamp: block-height,
        triggered-by: coordinator-id,
        notes: notes
      }
    )

    (map-set asset-event-counter
      { asset-id: asset-id }
      { count: new-count }
    )

    (ok new-count)
  )
)

;; Get asset details
(define-read-only (get-asset (asset-id uint))
  (map-get? assets { asset-id: asset-id })
)

;; Get ownership history
(define-read-only (get-ownership-history (asset-id uint) (transfer-id uint))
  (map-get? ownership-history { asset-id: asset-id, transfer-id: transfer-id })
)

;; Get lifecycle event
(define-read-only (get-lifecycle-event (asset-id uint) (event-id uint))
  (map-get? lifecycle-events { asset-id: asset-id, event-id: event-id })
)

;; Get asset transfer count
(define-read-only (get-transfer-count (asset-id uint))
  (default-to u0 (get count (map-get? asset-transfer-counter { asset-id: asset-id })))
)

;; Get asset event count
(define-read-only (get-event-count (asset-id uint))
  (default-to u0 (get count (map-get? asset-event-counter { asset-id: asset-id })))
)

;; Check asset status
(define-read-only (is-asset-active (asset-id uint))
  (match (map-get? assets { asset-id: asset-id })
    asset (is-eq (get lifecycle-stage asset) STAGE-ACTIVE)
    false
  )
)

;; Get assets by owner
(define-read-only (get-asset-owner (asset-id uint))
  (match (map-get? assets { asset-id: asset-id })
    asset (some (get current-owner asset))
    none
  )
)

;; Calculate asset age in blocks
(define-read-only (get-asset-age (asset-id uint))
  (match (map-get? assets { asset-id: asset-id })
    asset (some (- block-height (get created-at asset)))
    none
  )
)
