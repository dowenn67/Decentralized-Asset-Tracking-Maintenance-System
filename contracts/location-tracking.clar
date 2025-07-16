;; Location Tracking Contract
;; Tracks asset locations and movement history

;; Error constants
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-INVALID-INPUT (err u101))
(define-constant ERR-NOT-FOUND (err u102))
(define-constant ERR-ALREADY-EXISTS (err u103))
(define-constant ERR-INVALID-STATUS (err u104))

;; Asset location data
(define-map asset-locations
  { asset-id: uint }
  {
    current-location: (string-ascii 100),
    updated-at: uint,
    updated-by: (string-ascii 50),
    coordinates: (optional { lat: int, lng: int })
  }
)

;; Location history
(define-map location-history
  { asset-id: uint, sequence: uint }
  {
    location: (string-ascii 100),
    timestamp: uint,
    coordinator: (string-ascii 50),
    movement-type: (string-ascii 20),
    notes: (optional (string-ascii 200))
  }
)

;; Asset location sequence counter
(define-map asset-sequence-counter
  { asset-id: uint }
  { sequence: uint }
)

;; Update asset location
(define-public (update-location
  (asset-id uint)
  (location (string-ascii 100))
  (coordinator-id (string-ascii 50))
  (movement-type (string-ascii 20))
  (coordinates (optional { lat: int, lng: int }))
  (notes (optional (string-ascii 200))))
  (let (
    (current-sequence (default-to u0 (get sequence (map-get? asset-sequence-counter { asset-id: asset-id }))))
    (new-sequence (+ current-sequence u1))
  )
    (asserts! (> asset-id u0) ERR-INVALID-INPUT)
    (asserts! (> (len location) u0) ERR-INVALID-INPUT)
    (asserts! (> (len coordinator-id) u0) ERR-INVALID-INPUT)

    ;; Update current location
    (map-set asset-locations
      { asset-id: asset-id }
      {
        current-location: location,
        updated-at: block-height,
        updated-by: coordinator-id,
        coordinates: coordinates
      }
    )

    ;; Add to location history
    (map-set location-history
      { asset-id: asset-id, sequence: new-sequence }
      {
        location: location,
        timestamp: block-height,
        coordinator: coordinator-id,
        movement-type: movement-type,
        notes: notes
      }
    )

    ;; Update sequence counter
    (map-set asset-sequence-counter
      { asset-id: asset-id }
      { sequence: new-sequence }
    )

    (ok new-sequence)
  )
)

;; Get current asset location
(define-read-only (get-current-location (asset-id uint))
  (map-get? asset-locations { asset-id: asset-id })
)

;; Get location history entry
(define-read-only (get-location-history (asset-id uint) (sequence uint))
  (map-get? location-history { asset-id: asset-id, sequence: sequence })
)

;; Get latest sequence number for asset
(define-read-only (get-latest-sequence (asset-id uint))
  (default-to u0 (get sequence (map-get? asset-sequence-counter { asset-id: asset-id })))
)

;; Check if asset is at specific location
(define-read-only (is-asset-at-location (asset-id uint) (location (string-ascii 100)))
  (match (map-get? asset-locations { asset-id: asset-id })
    asset-location (is-eq (get current-location asset-location) location)
    false
  )
)

;; Get assets at location
(define-read-only (get-location-timestamp (asset-id uint))
  (match (map-get? asset-locations { asset-id: asset-id })
    asset-location (some (get updated-at asset-location))
    none
  )
)

;; Bulk location update for multiple assets
(define-public (bulk-update-location
  (asset-ids (list 10 uint))
  (location (string-ascii 100))
  (coordinator-id (string-ascii 50))
  (movement-type (string-ascii 20)))
  (begin
    (asserts! (> (len location) u0) ERR-INVALID-INPUT)
    (asserts! (> (len coordinator-id) u0) ERR-INVALID-INPUT)

    (ok (map update-single-location asset-ids))
  )
)

;; Helper function for bulk update
(define-private (update-single-location (asset-id uint))
  (let (
    (current-sequence (default-to u0 (get sequence (map-get? asset-sequence-counter { asset-id: asset-id }))))
    (new-sequence (+ current-sequence u1))
  )
    (map-set asset-locations
      { asset-id: asset-id }
      {
        current-location: "bulk-location",
        updated-at: block-height,
        updated-by: "bulk-coordinator",
        coordinates: none
      }
    )
    asset-id
  )
)

;; Get movement history count
(define-read-only (get-movement-count (asset-id uint))
  (get-latest-sequence asset-id)
)
