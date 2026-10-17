import SwiftUI
import FirebaseFirestore

struct JoinRideView: View {

    @State private var rideCode = ""

    @State private var isJoining = false
    @State private var showError = false

    @State private var rideName = ""
    @State private var errorMessage = ""

    @State private var showRideScreen = false
    @State private var joinedRideCode = ""

    // Persistent rider ID for this device
    @AppStorage("riderID") private var riderID = ""

    // Rider name
    @State private var riderName = ""

    private let db = Firestore.firestore()

    var body: some View {

        ZStack {

            LinearGradient(
                colors: [
                    Color.black,
                    Color.orange.opacity(0.35),
                    Color.black
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 28) {

                Spacer()

                // Motorcycle icon

                Image(systemName: "motorcycle.fill")
                    .font(.system(size: 70))
                    .foregroundStyle(.orange)

                Text("JOIN RIDE")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(.white)

                Text(
                    "Enter your name and the ride code shared by the ride leader"
                )
                .font(.subheadline)
                .foregroundStyle(.gray)
                .multilineTextAlignment(.center)

                // Rider name

                TextField("YOUR NAME", text: $riderName)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .foregroundStyle(.white)
                    .clipShape(
                        RoundedRectangle(cornerRadius: 12)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                Color.orange.opacity(0.7),
                                lineWidth: 1
                            )
                    )

                // Ride code

                TextField("ENTER RIDE CODE", text: $rideCode)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .multilineTextAlignment(.center)
                    .font(.system(size: 20, weight: .bold))
                    .tracking(4)
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .foregroundStyle(.white)
                    .clipShape(
                        RoundedRectangle(cornerRadius: 12)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                Color.orange.opacity(0.7),
                                lineWidth: 1
                            )
                    )
                    .onChange(of: rideCode) {

                        rideCode = String(
                            rideCode
                                .uppercased()
                                .filter {
                                    $0.isLetter || $0.isNumber
                                }
                                .prefix(6)
                        )
                    }

                // Join button

                Button {

                    Task {
                        await joinRide()
                    }

                } label: {

                    HStack {

                        if isJoining {

                            ProgressView()
                                .tint(.black)

                        } else {

                            Image(systemName: "motorcycle.fill")
                        }

                        Text(
                            isJoining
                            ? "JOINING..."
                            : "JOIN RIDE"
                        )
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange)
                    .foregroundStyle(.black)
                    .clipShape(
                        RoundedRectangle(cornerRadius: 12)
                    )
                }
                .disabled(
                    riderName
                        .trimmingCharacters(
                            in: .whitespacesAndNewlines
                        )
                        .isEmpty
                    ||
                    rideCode.count != 6
                    ||
                    isJoining
                )

                Spacer()
            }
            .padding(25)
        }

        .navigationTitle("Join Ride")
        .navigationBarTitleDisplayMode(.inline)

        // MARK: - Navigate to RideView

        .navigationDestination(
            isPresented: $showRideScreen
        ) {

            RideView(
                rideID: joinedRideCode
            )
        }

        // MARK: - Error

        .alert(
            "Unable to Join Ride",
            isPresented: $showError
        ) {

            Button("OK", role: .cancel) {}

        } message: {

            Text(errorMessage)
        }
    }

    // MARK: - Join Ride

    private func joinRide() async {

        let code = rideCode.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        let cleanRiderName = riderName.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard code.count == 6 else {

            errorMessage =
                "Please enter a valid 6-character ride code."

            showError = true

            return
        }

        guard !cleanRiderName.isEmpty else {

            errorMessage =
                "Please enter your name."

            showError = true

            return
        }

        isJoining = true

        // Create rider ID if this device does not have one

        if riderID.isEmpty {
            riderID = UUID().uuidString
        }

        do {

            // Get ride from Firebase

            let document = try await db
                .collection("rides")
                .document(code)
                .getDocument()

            guard let data = document.data() else {

                throw RideError.rideNotFound
            }

            let name =
                data["rideName"] as? String
                ?? "this ride"

            let members =
                data["members"] as? [String]
                ?? []

            let memberIDs =
                data["memberIDs"] as? [String]
                ?? []

            let maxRiders =
                data["maxRiders"] as? Int
                ?? 6

            // Check if this rider already joined

            if memberIDs.contains(riderID) {

                await MainActor.run {

                    rideName = name
                    joinedRideCode = code
                    isJoining = false
                    showRideScreen = true
                }

                return
            }

            // Check maximum riders

            if members.count >= maxRiders {

                throw RideError.rideFull
            }

            // Add rider to Firebase

            try await db
                .collection("rides")
                .document(code)
                .updateData([

                    "members": FieldValue.arrayUnion([
                        cleanRiderName
                    ]),

                    "memberIDs": FieldValue.arrayUnion([
                        riderID
                    ])
                ])

            // Open RideView

            await MainActor.run {

                rideName = name

                joinedRideCode = code

                isJoining = false

                showRideScreen = true
            }

        } catch {

            await MainActor.run {

                isJoining = false

                if let rideError = error as? RideError {

                    switch rideError {

                    case .rideNotFound:

                        errorMessage =
                            "No ride was found with this code."

                    case .rideFull:

                        errorMessage =
                            "This ride already has 6 riders."
                    }

                } else {

                    errorMessage =
                        error.localizedDescription
                }

                showError = true
            }
        }
    }
}

// MARK: - Ride Errors

private enum RideError: Error {

    case rideNotFound
    case rideFull
}

#Preview {

    NavigationStack {

        JoinRideView()
    }
}
