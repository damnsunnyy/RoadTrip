import SwiftUI
import FirebaseFirestore

struct CreateRideView: View {

    @State private var rideName = ""
    @State private var riderName = ""

    @State private var isCreating = false
    @State private var errorMessage = ""
    @State private var showError = false
    @State private var showRideScreen = false
    @State private var createdRideCode = ""

    // Unique ID for this rider
    @AppStorage("riderID") private var riderID = ""

    private let db = Firestore.firestore()

    var body: some View {

        NavigationStack {

            ScrollView {

                VStack(alignment: .leading, spacing: 24) {

                    // MARK: - Header

                    VStack(alignment: .leading, spacing: 10) {

                        Image(systemName: "motorcycle.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(.orange)

                        Text("Create a Ride")
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        Text("Set up your group ride and invite your riders.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    // MARK: - Ride Details

                    VStack(alignment: .leading, spacing: 12) {

                        Text("RIDE DETAILS")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(.secondary)

                        TextField("Ride name", text: $rideName)
                            .textFieldStyle(.roundedBorder)

                        Text("Example: Mumbai → Goa Road Trip")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    // MARK: - Rider Profile

                    VStack(alignment: .leading, spacing: 12) {

                        Text("YOUR RIDER PROFILE")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(.secondary)

                        TextField("Your name", text: $riderName)
                            .textFieldStyle(.roundedBorder)
                    }

                    // MARK: - Group Size

                    VStack(alignment: .leading, spacing: 10) {

                        Text("GROUP SIZE")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(.secondary)

                        HStack {

                            Image(systemName: "person.3.fill")
                                .foregroundStyle(.orange)

                            Text("Up to 6 riders")
                                .fontWeight(.medium)

                            Spacer()

                            Text("6 MAX")
                                .font(.caption)
                                .fontWeight(.bold)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(.orange.opacity(0.15))
                                .clipShape(Capsule())
                        }
                        .padding()
                        .background(.gray.opacity(0.1))
                        .clipShape(
                            RoundedRectangle(cornerRadius: 14)
                        )
                    }

                    // MARK: - Create Button

                    Button {

                        Task {
                            await createRide()
                        }

                    } label: {

                        HStack {

                            if isCreating {

                                ProgressView()
                                    .tint(.white)

                            } else {

                                Image(systemName: "motorcycle.fill")
                            }

                            Text(
                                isCreating
                                ? "Creating Ride..."
                                : "Create Ride"
                            )
                            .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                    .controlSize(.large)
                    .disabled(
                        rideName
                            .trimmingCharacters(
                                in: .whitespacesAndNewlines
                            )
                            .isEmpty
                        ||
                        riderName
                            .trimmingCharacters(
                                in: .whitespacesAndNewlines
                            )
                            .isEmpty
                        ||
                        isCreating
                    )
                }
                .padding()
            }

            .navigationTitle("New Ride")
            .navigationBarTitleDisplayMode(.inline)

            // MARK: - Navigate to RideView

            .navigationDestination(isPresented: $showRideScreen) {

                RideView(
                    rideID: createdRideCode
                )
            }

            // MARK: - Error Alert

            .alert(
                "Unable to Create Ride",
                isPresented: $showError
            ) {

                Button("OK", role: .cancel) {
                }

            } message: {

                Text(errorMessage)
            }
        }
    }

    // MARK: - Create Ride

    private func createRide() async {

        await MainActor.run {
            isCreating = true
        }

        let cleanRideName = rideName.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        let cleanRiderName = riderName.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        // Create a rider ID if this device does not have one yet

        if riderID.isEmpty {
            riderID = UUID().uuidString
        }

        do {

            // Generate unique 6-character ride code

            let code = try await generateUniqueRideCode()

            // Ride data saved to Firestore

            let rideData: [String: Any] = [

                "rideCode": code,

                "rideName": cleanRideName,

                "leaderName": cleanRiderName,

                "leaderID": riderID,

                "members": [
                    cleanRiderName
                ],

                "memberIDs": [
                    riderID
                ],

                "maxRiders": 6,

                "rideStarted": false,

                "createdAt": FieldValue.serverTimestamp()
            ]

            // Save ride to Firebase

            try await db
                .collection("rides")
                .document(code)
                .setData(rideData)

            // Store generated code and open RideView

            await MainActor.run {

                createdRideCode = code

                isCreating = false

                showRideScreen = true
            }

        } catch {

            await MainActor.run {

                isCreating = false

                errorMessage = error.localizedDescription

                showError = true
            }
        }
    }

    // MARK: - Generate Unique Ride Code

    private func generateUniqueRideCode() async throws -> String {

        let characters = Array(
            "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
        )

        while true {

            let code = String(
                (0..<6).map { _ in
                    characters.randomElement()!
                }
            )

            let document = try await db
                .collection("rides")
                .document(code)
                .getDocument()

            if !document.exists {
                return code
            }
        }
    }
}

#Preview {
    CreateRideView()
}
