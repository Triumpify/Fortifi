;; Bug Bounty Hunter Rewards Smart Contract

;; Constants
(define-constant security-chief tx-sender)
(define-constant err-chief-only (err u100))
(define-constant err-bounty-claimed (err u101))
(define-constant err-not-certified (err u102))
(define-constant err-no-bounty-assigned (err u103))
(define-constant err-claims-frozen (err u104))
(define-constant err-invalid-hunter (err u105))
(define-constant err-invalid-bounty (err u106))

;; Data Variables
(define-data-var total-bounty-treasury uint u5000000)
(define-data-var claims-available bool false)

;; Data Maps
(define-map hunter-bounties principal uint)          ;; Maps hunters to bounty rewards
(define-map bounty-claims principal bool)            ;; Tracks claim status
(define-map security-badges principal bool)          ;; Security badge holders
(define-map certified-hunters principal bool)        ;; Certified bug hunters

;; Private Functions
(define-private (is-security-chief)
    (is-eq tx-sender security-chief))

(define-private (is-certified-hunter (hunter principal))
    (and 
        (is-some (map-get? certified-hunters hunter))
        (is-some (map-get? security-badges hunter))))

(define-private (validate-hunter (hunter principal))
    (and
        (is-some (some hunter))
        (not (is-eq hunter security-chief))))

;; Public Functions

;; Certify hunter (chief only)
(define-public (certify-hunter (hunter principal))
    (begin
        (asserts! (is-security-chief) err-chief-only)
        (asserts! (validate-hunter hunter) err-invalid-hunter)
        (ok (map-set certified-hunters hunter true))))

;; Revoke certification (chief only)
(define-public (revoke-certification (hunter principal))
    (begin
        (asserts! (is-security-chief) err-chief-only)
        (asserts! (validate-hunter hunter) err-invalid-hunter)
        (ok (map-set certified-hunters hunter false))))

;; Award security badge (chief only)
(define-public (award-badge (hunter principal) (has-badge bool))
    (begin
        (asserts! (is-security-chief) err-chief-only)
        (asserts! (validate-hunter hunter) err-invalid-hunter)
        (ok (map-set security-badges hunter has-badge))))

;; Set bounty reward (chief only)
(define-public (set-bounty-reward (hunter principal) (reward uint))
    (begin
        (asserts! (is-security-chief) err-chief-only)
        (asserts! (validate-hunter hunter) err-invalid-hunter)
        (asserts! (> reward u0) err-invalid-bounty)
        (asserts! (<= reward (var-get total-bounty-treasury)) err-invalid-bounty)
        (ok (map-set hunter-bounties hunter reward))))

;; Claim bounty (public)
(define-public (claim-bounty)
    (let ((hunter tx-sender)
          (bounty-reward (unwrap! (map-get? hunter-bounties hunter) err-no-bounty-assigned)))
        (begin
            (asserts! (var-get claims-available) err-claims-frozen)
            (asserts! (is-certified-hunter hunter) err-not-certified)
            (asserts! (not (default-to false (map-get? bounty-claims hunter))) err-bounty-claimed)
            (map-set bounty-claims hunter true)
            (ok bounty-reward))))

;; Batch bounty payout (chief only)
(define-public (batch-bounty-payout (hunters (list 200 principal)) (rewards (list 200 uint)))
    (begin
        (asserts! (is-security-chief) err-chief-only)
        (asserts! (is-eq (len hunters) (len rewards)) err-invalid-bounty)
        (asserts! 
            (fold and 
                (map validate-hunter hunters) 
                true) 
            err-invalid-hunter)
        (asserts! 
            (fold and 
                (map is-valid-reward rewards)
                true) 
            err-invalid-bounty)
        (ok true)))

(define-private (is-valid-reward (reward uint))
    (> reward u0))

;; Toggle claims availability (chief only)
(define-public (toggle-claims)
    (begin
        (asserts! (is-security-chief) err-chief-only)
        (ok (var-set claims-available (not (var-get claims-available))))))

;; Read-only functions

(define-read-only (get-bounty-reward (hunter principal))
    (default-to u0 (map-get? hunter-bounties hunter)))

(define-read-only (has-claimed-bounty (hunter principal))
    (default-to false (map-get? bounty-claims hunter)))

(define-read-only (check-certification (hunter principal))
    (is-certified-hunter hunter))

(define-read-only (are-claims-available)
    (var-get claims-available))

(define-read-only (get-treasury-balance)
    (var-get total-bounty-treasury))

(define-read-only (get-hunter-profile (hunter principal))
    {
        bounty: (get-bounty-reward hunter),
        claimed: (has-claimed-bounty hunter),
        certified: (check-certification hunter),
        is-certified: (default-to false (map-get? certified-hunters hunter)),
        has-badge: (default-to false (map-get? security-badges hunter)),
        can-claim: (and 
            (var-get claims-available)
            (check-certification hunter)
            (not (has-claimed-bounty hunter))
            (> (get-bounty-reward hunter) u0)
        )
    })