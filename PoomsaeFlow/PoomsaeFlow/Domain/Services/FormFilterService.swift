import Foundation

/// Pure filtering function — no state, no side effects.
/// All service and presentation layers that need a form list go through here.
enum FormFilterService {

    /// Returns the subset of `allForms` that a user is eligible to practice,
    /// given their belt, their dojang's catalog, and which families they have enabled.
    ///
    /// Filter order matters:
    /// 1. Profile catalog gate (`formIDs`) — narrows the universe of forms for this school.
    /// 2. Belt eligibility — only forms introduced at or below the user's canonical rank.
    /// 3. Enabled families — user's session preference removes unwanted form types.
    ///    Pass `nil` to skip family filtering entirely (used by the Form Browser, which
    ///    shows all eligible forms regardless of session family preferences).
    ///
    /// Applying catalog gating first means belt + family logic always operates on the
    /// already-narrowed school catalog, not the full global list.
    nonisolated static func eligibleForms(
        userBelt: BeltLevel,
        profile: DojangProfile,
        allForms: [TKDForm],
        enabledFamilies: [FormFamily]? = nil
    ) -> [TKDForm] {
        // Step 1 — catalog gate: nil means no restriction (all forms visible to this school)
        let catalogForms: [TKDForm]
        if let allowedIDs = profile.formIDs {
            catalogForms = allForms.filter { allowedIDs.contains($0.id) }
        } else {
            catalogForms = allForms
        }

        // Step 2 — belt eligibility via canonical rank (never raw integer comparison)
        let beltOrder = userBelt.canonical.order
        let beltEligible = catalogForms.filter { $0.introducedAt.order <= beltOrder }

        // Step 3 — family filter (Set for O(1) lookup); nil means show all families
        guard let enabledFamilies else { return beltEligible }
        let enabledSet = Set(enabledFamilies)
        return beltEligible.filter { enabledSet.contains($0.family) }
    }
}
