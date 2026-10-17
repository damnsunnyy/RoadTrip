import SwiftUI

struct ContentView: View {

    var body: some View {

        NavigationStack {

            ZStack {

                LinearGradient(
                    colors: [
                        Color.black,
                        Color.orange.opacity(0.45),
                        Color.black
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 25) {

                    Spacer()

                    // Motorcycle

                    Image(systemName: "motorcycle.fill")
                        .font(.system(size: 70))
                        .foregroundStyle(.orange)

                    Text("ROADTRIP")
                        .font(.system(size: 38, weight: .heavy))
                        .foregroundStyle(.white)

                    Text("RIDE TOGETHER  ★  STAY CONNECTED")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.orange)

                    Spacer()

                    // CREATE RIDE

                    NavigationLink {

                        CreateRideView()

                    } label: {

                        HStack {

                            Image(systemName: "motorcycle.fill")
                                .font(.title2)

                            VStack(alignment: .leading) {

                                Text("CREATE RIDE")
                                    .font(.headline)

                                Text("Start a new group ride")
                                    .font(.caption)
                                    .opacity(0.8)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.orange)
                        .foregroundStyle(.black)
                        .clipShape(
                            RoundedRectangle(cornerRadius: 14)
                        )
                    }

                    // JOIN RIDE

                    NavigationLink {

                        JoinRideView()

                    } label: {

                        HStack {

                            Image(systemName: "motorcycle.fill")
                                .font(.title2)

                            VStack(alignment: .leading) {

                                Text("JOIN RIDE")
                                    .font(.headline)

                                Text("Join an existing ride")
                                    .font(.caption)
                                    .opacity(0.8)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            Color.white.opacity(0.12)
                        )
                        .foregroundStyle(.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(
                                    Color.white.opacity(0.3),
                                    lineWidth: 1
                                )
                        )
                        .clipShape(
                            RoundedRectangle(cornerRadius: 14)
                        )
                    }

                    Spacer()

                    // Bottom information

                    HStack {

                        VStack {
                            Image(systemName: "location.fill")
                            Text("LIVE LOCATION")
                        }

                        Spacer()

                        VStack {
                            Image(systemName: "person.3.fill")
                            Text("GROUP RIDES")
                        }

                        Spacer()

                        VStack {
                            Image(systemName: "person.3.fill")
                            Text("UP TO 6 RIDERS")
                        }
                    }
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.8))

                    Spacer()
                }
                .padding(25)
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    ContentView()
}
