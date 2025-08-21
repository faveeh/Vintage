;; Digital Art Gallery Collective Contract
;; Enables community-owned digital art galleries with curator governance and revenue sharing

;; Constants
(define-constant GALLERY_FOUNDER tx-sender)
(define-constant ERR_UNAUTHORIZED_MEMBER (err u600))
(define-constant ERR_INSUFFICIENT_SHARES (err u601))
(define-constant ERR_ARTWORK_NOT_FOUND (err u602))
(define-constant ERR_INVALID_PRICE (err u603))
(define-constant ERR_EXHIBITION_NOT_FOUND (err u604))
(define-constant ERR_ALREADY_CURATED (err u605))
(define-constant ERR_GALLERY_CLOSED (err u606))

;; Data Variables
(define-data-var next-artwork-id uint u1)
(define-data-var next-exhibition-id uint u1)
(define-data-var gallery-revenue uint u0)

;; Artwork Structure
(define-map digital-artworks
  { artwork-id: uint }
  {
    title: (string-ascii 120),
    artist: principal,
    medium: (string-ascii 50),
    creation-year: uint,
    base-price: uint,
    total-shares: uint,
    monthly-royalties: uint,
    is-displayed: bool,
    curator: principal
  }
)

;; Member Ownership Shares
(define-map member-shares
  { artwork-id: uint, member: principal }
  { shares: uint }
)

;; Exhibition Events
(define-map art-exhibitions
  { exhibition-id: uint }
  {
    artwork-id: uint,
    exhibition-name: (string-ascii 120),
    theme: (string-ascii 300),
    curator: principal,
    support-votes: uint,
    oppose-votes: uint,
    exhibition-end: uint,
    is-active: bool
  }
)

;; Curation Voting Records
(define-map curation-votes
  { exhibition-id: uint, curator: principal }
  { has-voted: bool, supports: bool }
)

;; Royalty Distribution Tracking
(define-map royalty-claims
  { artwork-id: uint, member: principal, period: uint }
  { has-claimed: bool }
)

;; Gallery Membership
(define-map gallery-members
  { member: principal }
  { 
    join-date: uint,
    total-investment: uint,
    curator-level: uint,
    is-active: bool
  }
)

;; Register New Artwork
(define-public (mint-artwork
  (title (string-ascii 120))
  (artist principal)
  (medium (string-ascii 50))
  (creation-year uint)
  (base-price uint)
  (total-shares uint)
  (monthly-royalties uint))
  (let ((artwork-id (var-get next-artwork-id)))
    (asserts! (is-eq tx-sender GALLERY_FOUNDER) ERR_UNAUTHORIZED_MEMBER)
    (asserts! (> total-shares u0) ERR_INVALID_PRICE)
    (asserts! (> base-price u0) ERR_INVALID_PRICE)
    
    (map-set digital-artworks
      { artwork-id: artwork-id }
      {
        title: title,
        artist: artist,
        medium: medium,
        creation-year: creation-year,
        base-price: base-price,
        total-shares: total-shares,
        monthly-royalties: monthly-royalties,
        is-displayed: true,
        curator: tx-sender
      }
    )
    
    (var-set next-artwork-id (+ artwork-id u1))
    (ok artwork-id)
  )
)

;; Join Gallery Collective
(define-public (join-gallery (investment-amount uint))
  (let ((current-member (map-get? gallery-members { member: tx-sender })))
    (asserts! (> investment-amount u0) ERR_INVALID_PRICE)
    
    (match current-member
      existing-member
        (map-set gallery-members
          { member: tx-sender }
          (merge existing-member { 
            total-investment: (+ (get total-investment existing-member) investment-amount),
            is-active: true
          })
        )
      (map-set gallery-members
        { member: tx-sender }
        {
          join-date: block-height,
          total-investment: investment-amount,
          curator-level: u1,
          is-active: true
        }
      )
    )
    
    (var-set gallery-revenue (+ (var-get gallery-revenue) investment-amount))
    (ok investment-amount)
  )
)

;; Purchase Artwork Shares
(define-public (acquire-shares (artwork-id uint) (share-count uint))
  (let (
    (artwork (unwrap! (map-get? digital-artworks { artwork-id: artwork-id }) ERR_ARTWORK_NOT_FOUND))
    (share-cost (* share-count (get base-price artwork)))
    (current-shares (default-to u0 (get shares (map-get? member-shares { artwork-id: artwork-id, member: tx-sender }))))
    (member-info (map-get? gallery-members { member: tx-sender }))
  )
    (asserts! (is-some member-info) ERR_UNAUTHORIZED_MEMBER)
    (asserts! (get is-displayed artwork) ERR_GALLERY_CLOSED)
    (asserts! (> share-count u0) ERR_INVALID_PRICE)
    
    (map-set member-shares
      { artwork-id: artwork-id, member: tx-sender }
      { shares: (+ current-shares share-count) }
    )
    
    (var-set gallery-revenue (+ (var-get gallery-revenue) share-cost))
    (ok share-count)
  )
)

;; Distribute Monthly Royalties
(define-public (distribute-royalties (artwork-id uint) (period uint))
  (let (
    (artwork (unwrap! (map-get? digital-artworks { artwork-id: artwork-id }) ERR_ARTWORK_NOT_FOUND))
    (monthly-royalties (get monthly-royalties artwork))
    (total-shares (get total-shares artwork))
  )
    (asserts! (is-eq tx-sender (get curator artwork)) ERR_UNAUTHORIZED_MEMBER)
    (asserts! (get is-displayed artwork) ERR_ARTWORK_NOT_FOUND)
    
    (ok true)
  )
)

;; Claim Royalty Share
(define-public (claim-royalties (artwork-id uint) (period uint))
  (let (
    (artwork (unwrap! (map-get? digital-artworks { artwork-id: artwork-id }) ERR_ARTWORK_NOT_FOUND))
    (member-shares-count (default-to u0 (get shares (map-get? member-shares { artwork-id: artwork-id, member: tx-sender }))))
    (already-claimed (default-to false (get has-claimed (map-get? royalty-claims { artwork-id: artwork-id, member: tx-sender, period: period }))))
    (monthly-royalties (get monthly-royalties artwork))
    (total-shares (get total-shares artwork))
    (member-royalty (/ (* monthly-royalties member-shares-count) total-shares))
  )
    (asserts! (> member-shares-count u0) ERR_INSUFFICIENT_SHARES)
    (asserts! (not already-claimed) ERR_UNAUTHORIZED_MEMBER)
    
    (map-set royalty-claims
      { artwork-id: artwork-id, member: tx-sender, period: period }
      { has-claimed: true }
    )
    
    (ok member-royalty)
  )
)

;; Create Art Exhibition
(define-public (propose-exhibition
  (artwork-id uint)
  (exhibition-name (string-ascii 120))
  (theme (string-ascii 300))
  (duration uint))
  (let (
    (exhibition-id (var-get next-exhibition-id))
    (member-shares-count (default-to u0 (get shares (map-get? member-shares { artwork-id: artwork-id, member: tx-sender }))))
    (exhibition-end (+ block-height duration))
    (member-info (unwrap! (map-get? gallery-members { member: tx-sender }) ERR_UNAUTHORIZED_MEMBER))
  )
    (asserts! (get is-active member-info) ERR_UNAUTHORIZED_MEMBER)
    (asserts! (>= (get curator-level member-info) u1) ERR_UNAUTHORIZED_MEMBER)
    
    (map-set art-exhibitions
      { exhibition-id: exhibition-id }
      {
        artwork-id: artwork-id,
        exhibition-name: exhibition-name,
        theme: theme,
        curator: tx-sender,
        support-votes: u0,
        oppose-votes: u0,
        exhibition-end: exhibition-end,
        is-active: false
      }
    )
    
    (var-set next-exhibition-id (+ exhibition-id u1))
    (ok exhibition-id)
  )
)

;; Vote on Exhibition Proposal
(define-public (curate-exhibition (exhibition-id uint) (supports bool))
  (let (
    (exhibition (unwrap! (map-get? art-exhibitions { exhibition-id: exhibition-id }) ERR_EXHIBITION_NOT_FOUND))
    (artwork-id (get artwork-id exhibition))
    (member-shares-count (default-to u0 (get shares (map-get? member-shares { artwork-id: artwork-id, member: tx-sender }))))
    (already-voted (default-to false (get has-voted (map-get? curation-votes { exhibition-id: exhibition-id, curator: tx-sender }))))
    (current-support (get support-votes exhibition))
    (current-opposition (get oppose-votes exhibition))
    (member-info (unwrap! (map-get? gallery-members { member: tx-sender }) ERR_UNAUTHORIZED_MEMBER))
  )
    (asserts! (get is-active member-info) ERR_UNAUTHORIZED_MEMBER)
    (asserts! (> member-shares-count u0) ERR_UNAUTHORIZED_MEMBER)
    (asserts! (<= block-height (get exhibition-end exhibition)) ERR_UNAUTHORIZED_MEMBER)
    (asserts! (not already-voted) ERR_ALREADY_CURATED)
    
    (map-set curation-votes
      { exhibition-id: exhibition-id, curator: tx-sender }
      { has-voted: true, supports: supports }
    )
    
    (if supports
      (map-set art-exhibitions
        { exhibition-id: exhibition-id }
        (merge exhibition { support-votes: (+ current-support member-shares-count) })
      )
      (map-set art-exhibitions
        { exhibition-id: exhibition-id }
        (merge exhibition { oppose-votes: (+ current-opposition member-shares-count) })
      )
    )
    
    (ok true)
  )
)

;; Upgrade Member Curator Level
(define-public (promote-curator (member principal) (new-level uint))
  (let ((member-info (unwrap! (map-get? gallery-members { member: member }) ERR_UNAUTHORIZED_MEMBER)))
    (asserts! (is-eq tx-sender GALLERY_FOUNDER) ERR_UNAUTHORIZED_MEMBER)
    (asserts! (<= new-level u5) ERR_INVALID_PRICE)
    
    (map-set gallery-members
      { member: member }
      (merge member-info { curator-level: new-level })
    )
    
    (ok new-level)
  )
)

;; Read-only functions
(define-read-only (get-artwork (artwork-id uint))
  (map-get? digital-artworks { artwork-id: artwork-id })
)

(define-read-only (get-member-shares (artwork-id uint) (member principal))
  (default-to u0 (get shares (map-get? member-shares { artwork-id: artwork-id, member: member })))
)

(define-read-only (get-exhibition (exhibition-id uint))
  (map-get? art-exhibitions { exhibition-id: exhibition-id })
)

(define-read-only (get-member-info (member principal))
  (map-get? gallery-members { member: member })
)

(define-read-only (calculate-member-royalty (artwork-id uint) (member principal))
  (let (
    (artwork (unwrap! (map-get? digital-artworks { artwork-id: artwork-id }) ERR_ARTWORK_NOT_FOUND))
    (member-shares-count (default-to u0 (get shares (map-get? member-shares { artwork-id: artwork-id, member: member }))))
    (monthly-royalties (get monthly-royalties artwork))
    (total-shares (get total-shares artwork))
  )
    (if (> member-shares-count u0)
      (ok (/ (* monthly-royalties member-shares-count) total-shares))
      (ok u0)
    )
  )
)

(define-read-only (get-gallery-stats)
  {
    total-revenue: (var-get gallery-revenue),
    next-artwork-id: (var-get next-artwork-id),
    next-exhibition-id: (var-get next-exhibition-id),
    founder: GALLERY_FOUNDER
  }
)