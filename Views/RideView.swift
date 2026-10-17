import SwiftUI

import Foundation

import FirebaseFirestore

import UIKit

import CoreLocation

import Combine

import MapKit

struct RideView: View {

    let rideID: String

    @State private var rideName = "Loading Ride..."

    @State private var leaderName = ""

    @State private var leaderID = ""

    @State private var members: [String] = []

    @State private var memberIDs: [String] = []

    @State private var maxRiders = 6

    @State private var isLoading = true

    @State private var errorMessage = ""

    @State private var listener: ListenerRegistration?

    @State private var rideStarted = false

    @State private var showLeaveAlert = false

    @State private var showCopiedMessage = false

    @State private var showTransferAlert = false

    @State private var selectedLeaderID = ""

    @State private var selectedLeaderName = ""

    @State private var isProcessing = false

    // Unique ID stored on this device

    @AppStorage("riderID") private var riderID = ""

    // GPS location manager for the current rider

    @StateObject private var locationManager = LocationManager()

    // Live locations of every rider in this ride

    @State private var riderLocations: [RiderLocation] = []

    @State private var locationListener: ListenerRegistration?

    @State private var hasCenteredMap = false

    @State private var mapPosition: MapCameraPosition = .region(

        MKCoordinateRegion(

            center: CLLocationCoordinate2D(latitude: 18.5204, longitude: 73.8567),

            span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)

        )

    )

    @Environment(\.dismiss) private var dismiss

    private let db = Firestore.firestore()

    // MARK: - Check Current Rider Role

    private var isLeader: Bool {

        !riderID.isEmpty && riderID == leaderID

    }

    // Current rider's display name for location data

    private var currentRiderName: String {

        guard let index = memberIDs.firstIndex(of: riderID),

              index < members.count else {

            return "Rider"

        }

        return members[index]

    }

    var body: some View {
        rideScreen
    }

    private var rideScreen: some View {
        mainContent
            .navigationTitle("Your Ride")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                startListening()
                startListeningLocations()
                locationManager.startUpdatingLocation()
            }
            .onReceive(locationManager.$location) { location in
                guard let location else { return }
                handleLocationUpdate(location)
            }
            .onDisappear {
                listener?.remove()
                listener = nil
                locationListener?.remove()
                locationListener = nil
                locationManager.stopUpdatingLocation()
            }
            .alert(
                "Ride Code Copied",
                isPresented: $showCopiedMessage
            ) {
                Button("OK") {}
            } message: {
                Text("\(rideID) has been copied to your clipboard.")
            }
            .alert(
                isLeader
                    ? "Transfer Leadership & Leave?"
                    : "Leave Ride?",
                isPresented: $showLeaveAlert
            ) {
                Button(
                    isLeader ? "Transfer & Leave" : "Leave",
                    role: .destructive
                ) {
                    leaveRide()
                }

                Button("Cancel", role: .cancel) {}
            } message: {
                if isLeader {
                    Text(leaderLeaveMessage)
                } else {
                    Text("You will be removed from \(rideName).")
                }
            }
            .alert(
                "Transfer Leadership?",
                isPresented: $showTransferAlert
            ) {
                Button("Transfer", role: .destructive) {
                    transferLeadership(to: selectedLeaderID)
                }

                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Make \(selectedLeaderName) the new ride leader?")
            }
            .alert(
                "Ride Error",
                isPresented: Binding(
                    get: { !errorMessage.isEmpty },
                    set: { newValue in
                        if !newValue {
                            errorMessage = ""
                        }
                    }
                )
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
    }

    private var mainContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                headerSection
                rideCodeSection
                liveMapSection
                ridersSection
                leadershipInfoSection
                startRideSection
                leaveRideButton
            }
            .padding()
        }
    }

    private var headerSection: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(.orange.opacity(0.15))
                    .frame(width: 90, height: 90)

                Image(systemName: "motorcycle.fill")
                    .font(.system(size: 45))
                    .foregroundStyle(.orange)
            }

            Text("ROADTRIP")
                .font(.title)
                .fontWeight(.black)
                .tracking(2)

            Text(rideName)
                .font(.headline)
                .foregroundStyle(.secondary)

            HStack(spacing: 6) {
                Circle()
                    .fill(rideStarted ? .green : .orange)
                    .frame(width: 8, height: 8)

                Text(rideStarted ? "RIDE IN PROGRESS" : "WAITING TO START")
                    .font(.caption)
                    .fontWeight(.bold)
            }
            .foregroundStyle(rideStarted ? .green : .orange)

            HStack(spacing: 6) {
                Image(systemName: isLeader ? "crown.fill" : "person.fill")

                Text(isLeader ? "RIDE LEADER" : "RIDER")
                    .font(.caption)
                    .fontWeight(.bold)
            }
            .foregroundStyle(isLeader ? .orange : .secondary)
        }
        .padding(.top, 10)
    }

    private var ridersSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("RIDERS")
                        .font(.headline)
                        .fontWeight(.bold)

                    Text("Everyone in this ride")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(riderCountDisplay)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(.orange)
            }

            if isLoading {
                HStack {
                    ProgressView()
                    Text("Loading riders...")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
            } else if members.isEmpty {
                Text("No riders found")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(riderRows) { rider in
                    RiderRow(
                        name: rider.name,
                        isLeader: rider.isLeader,
                        canTransfer: rider.canTransfer
                    ) {
                        handleTransferTap(
                            memberID: rider.id,
                            memberName: rider.name
                        )
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.gray.opacity(0.08))
        )
    }

    private var leadershipInfoSection: some View {
        Group {
            if isLeader && members.count > 1 {
                HStack(spacing: 10) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .foregroundStyle(.orange)

                    Text("Tap the transfer button beside a rider to make them the new leader.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer()
                }
                .padding()
                .background(.orange.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
    }

    private var startRideSection: some View {
        Group {
            if isLeader {
                Button {
                    startRide()
                } label: {
                    HStack {
                        Image(
                            systemName: rideStarted
                                ? "location.fill"
                                : "flag.checkered"
                        )

                        Text(
                            rideStarted
                                ? "Ride In Progress"
                                : "Start Ride"
                        )
                        .fontWeight(.bold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
                .controlSize(.large)
                .disabled(rideStarted || isProcessing)
            } else {
                HStack(spacing: 10) {
                    Image(systemName: "hourglass")
                        .foregroundStyle(.secondary)

                    Text(
                        rideStarted
                            ? "Ride has started"
                            : "Waiting for the ride leader to start"
                    )
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(.gray.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
    }

    private var leaveRideButton: some View {
        Button(role: .destructive) {
            showLeaveAlert = true
        } label: {
            HStack {
                Image(systemName: "rectangle.portrait.and.arrow.right")

                Text(
                    isLeader
                        ? "Leave & Pass Leadership"
                        : "Leave Ride"
                )
                .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 5)
        }
        .disabled(isProcessing)
    }

    private struct RideListRider: Identifiable {
        let id: String
        let name: String
        let isLeader: Bool
        let canTransfer: Bool
    }

    private var riderRows: [RideListRider] {
        var rows: [RideListRider] = []
        rows.reserveCapacity(members.count)

        for index in members.indices {
            let name = members[index]
            let id = index < memberIDs.count ? memberIDs[index] : ""

            rows.append(
                RideListRider(
                    id: id.isEmpty ? "member-\(index)" : id,
                    name: name,
                    isLeader: id == leaderID,
                    canTransfer: isLeader &&
                        id != riderID &&
                        !id.isEmpty
                )
            )
        }

        return rows
    }

    private var riderCountDisplay: String {

        let count = members.count

        let maximum = maxRiders

        return "\(count) / \(maximum)"

    }

    // MARK: - Ride Code Section

    @ViewBuilder

    private var rideCodeSection: some View {

VStack(spacing: 14) {

                    HStack {

                        VStack(

                            alignment: .leading,

                            spacing: 4

                        ) {

                            Text("RIDE CODE")

                                .font(.caption)

                                .fontWeight(.bold)

                                .foregroundStyle(.secondary)

                            Text(rideID)

                                .font(

                                    .system(

                                        size: 32,

                                        weight: .black

                                    )

                                )

                                .tracking(5)

                                .foregroundStyle(.orange)

                        }

                        Spacer()

                        // Only leader can copy

                        if isLeader {

                            Button {

                                UIPasteboard.general.string =

                                    rideID

                                showCopiedMessage = true

                            } label: {

                                Image(

                                    systemName:

                                        "doc.on.doc"

                                )

                                .font(.title3)

                                .frame(

                                    width: 44,

                                    height: 44

                                )

                            }

                            .buttonStyle(.bordered)

                        }

                    }

                    // Only leader gets the full copy button

                    if isLeader {

                        Button {

                            UIPasteboard.general.string =

                                rideID

                            showCopiedMessage = true

                        } label: {

                            Label(

                                "Copy Ride Code",

                                systemImage:

                                    "doc.on.doc"

                            )

                            .fontWeight(.semibold)

                            .frame(

                                maxWidth: .infinity

                            )

                        }

                        .buttonStyle(

                            .borderedProminent

                        )

                        .tint(.orange)

                    } else {

                        HStack(spacing: 8) {

                            Image(

                                systemName:

                                    "person.fill"

                            )

                            .foregroundStyle(

                                .secondary

                            )

                            Text(

                                "Only the ride leader can share the ride code."

                            )

                            .font(.caption)

                            .foregroundStyle(

                                .secondary

                            )

                        }

                    }

                }

                .padding()

                .background(

                    RoundedRectangle(

                        cornerRadius: 20

                    )

                    .fill(

                        .orange.opacity(0.08)

                    )

                )

    }

    private func handleLocationUpdate(_ location: CLLocation) {

        print(

            "GPS update: lat=\(location.coordinate.latitude), " +

            "lon=\(location.coordinate.longitude), " +

            "rideStarted=\(rideStarted), " +

            "riderID=\(riderID)"

        )

        uploadCurrentLocation(location)

        guard !hasCenteredMap else { return }

        let region = MKCoordinateRegion(

            center: location.coordinate,

            span: MKCoordinateSpan(

                latitudeDelta: 0.02,

                longitudeDelta: 0.02

            )

        )

        mapPosition = .region(region)

        hasCenteredMap = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            fitMapToRiders()
        }

    }

    private func handleTransferTap(

        memberID: String,

        memberName: String

    ) {

        selectedLeaderID = memberID

        selectedLeaderName = memberName

        showTransferAlert = true

    }

    // MARK: - Live Map Section

    @ViewBuilder

    private var liveMapSection: some View {

        VStack(alignment: .leading, spacing: 12) {

            liveMapHeader

            if locationManager.location != nil {

                liveMapView

            } else {

                locationWaitingView

            }

        }

    }

    private var liveMapHeader: some View {

        HStack {

            Image(systemName: "map.fill")

                .foregroundStyle(.orange)

            Text("LIVE MAP")

                .font(.headline)

                .fontWeight(.bold)

            Spacer()

            if rideStarted {

                HStack(spacing: 5) {

                    Circle()

                        .fill(.green)

                        .frame(width: 7, height: 7)

                    Text("LIVE")

                        .font(.caption)

                        .fontWeight(.bold)

                        .foregroundStyle(.green)

                }

            }

        }

    }

    private var locationWaitingView: some View {

        ZStack {

            RoundedRectangle(cornerRadius: 18)

                .fill(.gray.opacity(0.12))

            VStack(spacing: 10) {

                Image(systemName: "location.slash")

                    .font(.system(size: 42))

                    .foregroundStyle(.secondary)

                Text(locationStatusMessage)

                    .font(.subheadline)

                    .fontWeight(.medium)

                    .multilineTextAlignment(.center)

                    .foregroundStyle(.secondary)

            }

        }

        .frame(height: 300)

    }

    private var liveMapView: some View {
        Map(position: $mapPosition) {
            ForEach(mapRiderLocations) { rider in
                Annotation(
                    rider.id == riderID ? "You" : rider.riderName,
                    coordinate: rider.coordinate
                ) {
                    riderAnnotation(rider)
                }
            }
        }
        .mapStyle(.standard)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(alignment: .topLeading) {
            riderCountBadge
        }
        .overlay(alignment: .bottomTrailing) {
            Button {
                fitMapToRiders()
            } label: {
                Image(systemName: "location.fill")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(width: 42, height: 42)
                    .background(.orange)
                    .clipShape(Circle())
                    .shadow(radius: 3)
            }
            .padding(10)
        }
        .frame(height: 300)
    }

    private var mapRiderLocations: [RiderLocation] {
        var locations = riderLocations

        if let currentLocation = locationManager.location, !riderID.isEmpty {
            let localRider = RiderLocation(
                id: riderID,
                riderName: currentRiderName,
                latitude: currentLocation.coordinate.latitude,
                longitude: currentLocation.coordinate.longitude,
                speed: max(currentLocation.speed, 0)
            )

            if let index = locations.firstIndex(where: { $0.id == riderID }) {
                locations[index] = localRider
            } else {
                locations.append(localRider)
            }
        }

        return locations
    }

    private func fitMapToRiders() {
        let riders = mapRiderLocations

        guard !riders.isEmpty else {
            print("MAP: No rider locations available yet.")
            return
        }

        if riders.count == 1, let rider = riders.first {
            mapPosition = .region(
                MKCoordinateRegion(
                    center: rider.coordinate,
                    span: MKCoordinateSpan(
                        latitudeDelta: 0.02,
                        longitudeDelta: 0.02
                    )
                )
            )
            return
        }

        let latitudes = riders.map { $0.latitude }
        let longitudes = riders.map { $0.longitude }

        guard
            let minLatitude = latitudes.min(),
            let maxLatitude = latitudes.max(),
            let minLongitude = longitudes.min(),
            let maxLongitude = longitudes.max()
        else {
            return
        }

        let center = CLLocationCoordinate2D(
            latitude: (minLatitude + maxLatitude) / 2,
            longitude: (minLongitude + maxLongitude) / 2
        )

        let latitudeDelta = max((maxLatitude - minLatitude) * 1.6, 0.02)
        let longitudeDelta = max((maxLongitude - minLongitude) * 1.6, 0.02)

        mapPosition = .region(
            MKCoordinateRegion(
                center: center,
                span: MKCoordinateSpan(
                    latitudeDelta: latitudeDelta,
                    longitudeDelta: longitudeDelta
                )
            )
        )

        print("MAP: Fitted \(riders.count) riders.")
    }

    private func riderAnnotation(_ rider: RiderLocation) -> some View {
        VStack(spacing: 2) {
            Image(systemName: "motorcycle.fill")
                .font(.system(size: 28))
                .foregroundStyle(rider.id == riderID ? .orange : .blue)
                .padding(8)
                .background(.white)
                .clipShape(Circle())
                .shadow(radius: 4)

            Text(rider.id == riderID ? "YOU" : rider.riderName)
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(.white)
                .clipShape(Capsule())
                .shadow(radius: 2)
        }
    }

    private var riderCountBadge: some View {

        HStack(spacing: 6) {

            Circle()

                .fill(.green)

                .frame(width: 8, height: 8)

            Text(riderCountText)

                .font(.caption)

                .fontWeight(.bold)

        }

        .padding(.horizontal, 10)

        .padding(.vertical, 7)

        .background(.ultraThinMaterial)

        .clipShape(Capsule())

        .padding(10)

    }

    private var riderCountText: String {

        let suffix = riderLocations.count == 1 ? "" : "S"

        return "\(riderLocations.count) RIDER\(suffix) LIVE"

    }

    // MARK: - GPS Status

    private var locationStatusMessage: String {

        switch locationManager.authorizationStatus {

        case .notDetermined:

            return "Requesting location permission..."

        case .restricted:

            return "Location access is restricted on this iPhone."

        case .denied:

            return "Location access is disabled. Enable it in Settings."

        case .authorizedWhenInUse, .authorizedAlways:

            return "Waiting for your GPS location..."

        @unknown default:

            return "Waiting for GPS permission..."

        }

    }

    // MARK: - Leader Leave Message

    private var leaderLeaveMessage: String {

        if members.count > 1 {

            return "You are the current leader. Leadership will automatically pass to the next rider in the list, and the ride will continue."

        } else {

            return "You are the only rider. Leaving will end this ride."

        }

    }

    // MARK: - Start Ride

    private func startRide() {

        // Extra protection inside the function

        guard isLeader else {

            return

        }

        guard !rideStarted else {

            return

        }

        rideStarted = true

        db

            .collection("rides")

            .document(rideID)

            .updateData([

                "rideStarted": true

            ])

        // Upload the current position immediately when the ride starts.

        if let currentLocation = locationManager.location {

            print("Ride started. Uploading current GPS location now.")

            uploadCurrentLocation(currentLocation)

        } else {

            print("Ride started, but no GPS location is available yet.")

            locationManager.startUpdatingLocation()

        }

    }

    // MARK: - Upload Current Location

    private func uploadCurrentLocation(_ location: CLLocation) {

        guard rideStarted else {

            print("Location upload skipped: ride has not started.")

            return

        }

        guard !riderID.isEmpty else {

            print("Location upload skipped: riderID is empty.")

            return

        }

        var locationData: [String: Any] = [

            "riderID": riderID,

            "riderName": currentRiderName,

            "latitude": location.coordinate.latitude,

            "longitude": location.coordinate.longitude,

            "speed": max(location.speed, 0),

            "updatedAt": FieldValue.serverTimestamp()

        ]

        if location.course >= 0 {

            locationData["heading"] = location.course

        }

        db

            .collection("rides")

            .document(rideID)

            .collection("locations")

            .document(riderID)

            .setData(locationData, merge: true) { error in

                if let error = error {

                    print("Location upload error: \(error.localizedDescription)")

                } else {

                    print("Location uploaded successfully: \(self.rideID)/locations/\(self.riderID)")

                }

            }

    }

    // MARK: - Listen For All Rider Locations

    private func startListeningLocations() {

        locationListener?.remove()

        let locationsReference = db

            .collection("rides")

            .document(rideID)

            .collection("locations")

        print("Starting location listener for ride: \(rideID)")

        locationListener = locationsReference.addSnapshotListener { snapshot, error in

            if let error = error {

                print("Location listener error: \(error.localizedDescription)")

                return

            }

            guard let snapshot = snapshot else {

                print("Location listener returned no snapshot.")

                return

            }

            var locations: [RiderLocation] = []

            for document in snapshot.documents {

                let data = document.data()

                guard

                    let latitude = doubleValue(from: data["latitude"]),

                    let longitude = doubleValue(from: data["longitude"])

                else {

                    print("Skipping location document: \(document.documentID)")

                    continue

                }

                let riderIDFromDocument =

                    data["riderID"] as? String ?? document.documentID

                let riderName =

                    data["riderName"] as? String ?? "Rider"

                let speed =

                    doubleValue(from: data["speed"]) ?? 0

                let riderLocation = RiderLocation(

                    id: riderIDFromDocument,

                    riderName: riderName,

                    latitude: latitude,

                    longitude: longitude,

                    speed: speed

                )

                locations.append(riderLocation)

                print(

                    "Received rider location: \(riderName) | ID: \(riderIDFromDocument) | lat: \(latitude) | lon: \(longitude)"

                )

            }

            DispatchQueue.main.async {
                riderLocations = locations

                print("Total riders visible on map: \(locations.count)")

                for rider in locations {
                    print(
                        "MAP RIDER -> \(rider.riderName): \(rider.latitude), \(rider.longitude)"
                    )
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    fitMapToRiders()
                }
            }

        }

    }

    private func doubleValue(from value: Any?) -> Double? {

        if let value = value as? Double {

            return value

        }

        if let value = value as? Int {

            return Double(value)

        }

        if let value = value as? Int64 {

            return Double(value)

        }

        if let value = value as? NSNumber {

            return value.doubleValue

        }

        return nil

    }

    // MARK: - Transfer Leadership

    private func transferLeadership(

        to newLeaderID: String

    ) {

        // Only the current leader can transfer leadership

        guard isLeader else {

            return

        }

        // Cannot transfer to yourself

        guard newLeaderID != riderID else {

            return

        }

        // Find the selected rider

        guard let index =

            memberIDs.firstIndex(

                of: newLeaderID

            )

        else {

            errorMessage =

                "The selected rider could not be found."

            return

        }

        guard index < members.count else {

            errorMessage =

                "The selected rider could not be found."

            return

        }

        let newLeaderName =

            members[index]

        isProcessing = true

        Task {

            do {

                // Update the leader in Firestore

                try await db

                    .collection("rides")

                    .document(rideID)

                    .updateData([

                        "leaderID":

                            newLeaderID,

                        "leaderName":

                            newLeaderName

                    ])

                await MainActor.run {

                    isProcessing = false

                }

            } catch {

                await MainActor.run {

                    isProcessing = false

                    errorMessage =

                        error.localizedDescription

                }

            }

        }

    }

    // MARK: - Leave Ride

    private func leaveRide() {

        guard !riderID.isEmpty else {

            print("Location upload skipped: riderID is empty.")

            errorMessage =

                "Unable to identify this rider."

            return

        }

        isProcessing = true

        Task {

            do {

                let rideReference =

                    db

                        .collection("rides")

                        .document(rideID)

                let locationReference =

                    rideReference

                        .collection("locations")

                        .document(riderID)

                let document =

                    try await rideReference

                        .getDocument()

                guard let data =

                    document.data()

                else {

                    throw RideError.rideNotFound

                }

                var currentMembers =

                    data["members"] as? [String]

                    ?? []

                var currentMemberIDs =

                    data["memberIDs"] as? [String]

                    ?? []

                let currentLeaderID =

                    data["leaderID"] as? String

                    ?? ""

                // MARK: Leader Leaving

                if riderID == currentLeaderID {

                    // Find current leader in the rider list

                    guard let leaderIndex =

                        currentMemberIDs.firstIndex(

                            of: riderID

                        )

                    else {

                        throw RideError.riderNotFound

                    }

                    // Remove the current leader

                    currentMemberIDs.remove(

                        at: leaderIndex

                    )

                    if leaderIndex <

                        currentMembers.count {

                        currentMembers.remove(

                            at: leaderIndex

                        )

                    }

                    // If nobody remains, delete the ride

                    if currentMemberIDs.isEmpty {

                        try await rideReference.delete()

                        await MainActor.run {

                            isProcessing = false

                            dismiss()

                        }

                        return

                    }

                    // The first remaining rider becomes leader.

                    //

                    // When the original leader was first in

                    // the list, this is the second person.

                    let newLeaderID =

                        currentMemberIDs[0]

                    let newLeaderName =

                        currentMembers[0]

                    try await locationReference.delete()

                    try await rideReference

                        .updateData([

                            "members":

                                currentMembers,

                            "memberIDs":

                                currentMemberIDs,

                            "leaderID":

                                newLeaderID,

                            "leaderName":

                                newLeaderName

                        ])

                    await MainActor.run {

                        isProcessing = false

                        dismiss()

                    }

                } else {

                    // MARK: Normal Rider Leaving

                    guard let riderIndex =

                        currentMemberIDs.firstIndex(

                            of: riderID

                        )

                    else {

                        throw RideError.riderNotFound

                    }

                    // Remove rider ID

                    currentMemberIDs.remove(

                        at: riderIndex

                    )

                    // Remove matching rider name

                    if riderIndex <

                        currentMembers.count {

                        currentMembers.remove(

                            at: riderIndex

                        )

                    }

                    try await locationReference.delete()

                    try await rideReference

                        .updateData([

                            "members":

                                currentMembers,

                            "memberIDs":

                                currentMemberIDs

                        ])

                    await MainActor.run {

                        isProcessing = false

                        dismiss()

                    }

                }

            } catch {

                await MainActor.run {

                    isProcessing = false

                    if let rideError =

                        error as? RideError {

                        switch rideError {

                        case .rideNotFound:

                            errorMessage =

                                "This ride no longer exists."

                        case .riderNotFound:

                            errorMessage =

                                "Your rider account could not be found in this ride."

                        }

                    } else {

                        errorMessage =

                            error.localizedDescription

                    }

                }

            }

        }

    }

    // MARK: - Firestore Listener

    private func startListening() {

        listener?.remove()

        listener =

            db

                .collection("rides")

                .document(rideID)

                .addSnapshotListener {

                    snapshot,

                    error in

                    DispatchQueue.main.async {

                        if let error = error {

                            errorMessage =

                                error.localizedDescription

                            isLoading = false

                            return

                        }

                        guard let data =

                            snapshot?.data()

                        else {

                            errorMessage =

                                "Ride not found."

                            isLoading = false

                            return

                        }

                        rideName =

                            data["rideName"]

                            as? String

                            ?? "Unnamed Ride"

                        leaderName =

                            data["leaderName"]

                            as? String

                            ?? ""

                        // IMPORTANT:

                        // Get the leader's unique ID

                        leaderID =

                            data["leaderID"]

                            as? String

                            ?? ""

                        members =

                            data["members"]

                            as? [String]

                            ?? []

                        memberIDs =

                            data["memberIDs"]

                            as? [String]

                            ?? []

                        maxRiders =

                            data["maxRiders"]

                            as? Int

                            ?? 6

                        rideStarted =

                            data["rideStarted"]

                            as? Bool

                            ?? false

                        isLoading = false

                    }

                }

    }

}

// MARK: - Live Rider Location

private struct RiderLocation: Identifiable {

    let id: String

    let riderName: String

    let latitude: Double

    let longitude: Double

    let speed: Double

    var coordinate: CLLocationCoordinate2D {

        CLLocationCoordinate2D(

            latitude: latitude,

            longitude: longitude

        )

    }

}

// MARK: - Rider Row

struct RiderRow: View {

    let name: String

    let isLeader: Bool

    let canTransfer: Bool

    let transferAction: () -> Void

    var body: some View {

        HStack(spacing: 14) {

            ZStack {

                Circle()

                    .fill(

                        .orange.opacity(0.15)

                    )

                    .frame(

                        width: 44,

                        height: 44

                    )

                Image(

                    systemName:

                        "motorcycle.fill"

                )

                .foregroundStyle(

                    .orange

                )

            }

            VStack(

                alignment: .leading,

                spacing: 3

            ) {

                Text(name)

                    .fontWeight(.semibold)

                if isLeader {

                    Text("Ride Leader")

                        .font(.caption)

                        .foregroundStyle(

                            .orange

                        )

                } else {

                    Text("Rider")

                        .font(.caption)

                        .foregroundStyle(

                            .secondary

                        )

                }

            }

            Spacer()

            if isLeader {

                Image(

                    systemName:

                        "crown.fill"

                )

                .foregroundStyle(

                    .orange

                )

            } else if canTransfer {

                Button {

                    transferAction()

                } label: {

                    Image(

                        systemName:

                            "arrow.triangle.2.circlepath"

                    )

                    .font(.headline)

                    .foregroundStyle(

                        .orange

                    )

                    .frame(

                        width: 40,

                        height: 40

                    )

                }

                .buttonStyle(.bordered)

            }

        }

        .padding(.vertical, 4)

    }

}

// MARK: - Ride Errors

private enum RideError: Error {

    case rideNotFound

    case riderNotFound

}

