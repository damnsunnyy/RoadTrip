import SwiftUI
import FirebaseFirestore

struct RideDetailView: View {
    
    let rideCode: String
    
    @State private var rideName = ""
    @State private var leaderName = ""
    @State private var members: [String] = []
    @State private var maxRiders = 6
    @State private var isLoading = true
    @State private var errorMessage = ""
    @State private var showError = false
    @State private var showCopied = false
    
    private let db = Firestore.firestore()
    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            if isLoading {
                
                ProgressView("Loading Ride...")
                    .tint(.orange)
                    .foregroundStyle(.white)
                
            } else {
                
                ScrollView {
                    VStack(spacing: 24) {
                        
                        // MARK: Motorcycle Header
                        
                        VStack(spacing: 12) {
                            
                            Image(systemName: "motorcycle.fill")
                                .font(.system(size: 60))
                                .foregroundStyle(.orange)
                            
                            Text("ROADTRIP")
                                .font(.system(size: 32, weight: .heavy))
                                .foregroundStyle(.white)
                            
                            Text("RIDE TOGETHER. STAY CONNECTED.")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundStyle(.orange)
                        }
                        .padding(.top, 20)
                        
                        // MARK: Ride Name
                        
                        VStack(alignment: .leading, spacing: 8) {
                            
                            Text("YOUR RIDE")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundStyle(.gray)
                            
                            Text(rideName)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                            
                            Text("Led by \(leaderName)")
                                .font(.subheadline)
                                .foregroundStyle(.gray)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        // MARK: Ride Code
                        
                        VStack(spacing: 12) {
                            
                            Text("RIDE CODE")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundStyle(.gray)
                            
                            Text(rideCode)
                                .font(.system(size: 36, weight: .heavy, design: .monospaced))
                                .tracking(5)
                                .foregroundStyle(.orange)
                            
                            Button {
                                UIPasteboard.general.string = rideCode
                                showCopied = true
                                
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    showCopied = false
                                }
                            } label: {
                                HStack {
                                    Image(systemName: showCopied ? "checkmark" : "doc.on.doc")
                                    Text(showCopied ? "Copied!" : "Copy Ride Code")
                                }
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(.orange.opacity(0.2))
                                .clipShape(Capsule())
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 25)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.white.opacity(0.08))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(.orange.opacity(0.4), lineWidth: 1)
                        )
                        
                        // MARK: Riders
                        
                        VStack(alignment: .leading, spacing: 14) {
                            
                            HStack {
                                Text("RIDERS")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.gray)
                                
                                Spacer()
                                
                                Text("\(members.count) / \(maxRiders)")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.orange)
                            }
                            
                            ForEach(Array(members.enumerated()), id: \.offset) { index, member in
                                
                                HStack(spacing: 14) {
                                    
                                    ZStack {
                                        Circle()
                                            .fill(.orange.opacity(0.2))
                                            .frame(width: 42, height: 42)
                                        
                                        Image(systemName: "motorcycle.fill")
                                            .foregroundStyle(.orange)
                                    }
                                    
                                    VStack(alignment: .leading) {
                                        Text(member)
                                            .fontWeight(.semibold)
                                            .foregroundStyle(.white)
                                        
                                        Text(index == 0 ? "Ride Leader" : "Rider")
                                            .font(.caption)
                                            .foregroundStyle(.gray)
                                    }
                                    
                                    Spacer()
                                    
                                    if index == 0 {
                                        Text("LEADER")
                                            .font(.caption2)
                                            .fontWeight(.bold)
                                            .foregroundStyle(.orange)
                                    }
                                }
                                .padding()
                                .background(Color.white.opacity(0.06))
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                        }
                        
                        // MARK: Live Location
                        
                        Button {
                            // Live location will be added next
                        } label: {
                            HStack(spacing: 14) {
                                
                                Image(systemName: "location.fill")
                                    .font(.title3)
                                    .foregroundStyle(.green)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("LIVE LOCATION")
                                        .fontWeight(.bold)
                                        .foregroundStyle(.white)
                                    
                                    Text("Location sharing will be available here")
                                        .font(.caption)
                                        .foregroundStyle(.gray)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.gray)
                            }
                            .padding()
                            .background(Color.white.opacity(0.07))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        
                        // MARK: Start Ride
                        
                        Button {
                            // Start Ride will be implemented next
                        } label: {
                            HStack {
                                Image(systemName: "flag.checkered")
                                Text("START RIDE")
                            }
                            .font(.headline)
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.orange)
                            .foregroundStyle(.black)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        
                        // MARK: Leave Ride
                        
                        Button {
                            // Leave Ride will be implemented later
                        } label: {
                            Text("Leave Ride")
                                .font(.subheadline)
                                .foregroundStyle(.red)
                        }
                    }
                    .padding(20)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadRide()
        }
        .alert("Unable to Load Ride", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: Load Ride
    
    private func loadRide() async {
        
        do {
            let document = try await db
                .collection("rides")
                .document(rideCode)
                .getDocument()
            
            guard let data = document.data() else {
                errorMessage = "This ride could not be found."
                showError = true
                isLoading = false
                return
            }
            
            rideName = data["rideName"] as? String ?? "RoadTrip"
            leaderName = data["leaderName"] as? String ?? "Rider"
            members = data["members"] as? [String] ?? []
            maxRiders = data["maxRiders"] as? Int ?? 6
            
            isLoading = false
            
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            isLoading = false
        }
    }
}

#Preview {
    NavigationStack {
        RideDetailView(rideCode: "ABC123")
    }
}
