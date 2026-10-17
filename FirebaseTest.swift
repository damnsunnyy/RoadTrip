import Foundation
import FirebaseFirestore

func testFirebaseConnection() {
    let db = Firestore.firestore()

    db.collection("test").document("connection").setData([
        "message": "Firebase is working",
        "timestamp": Date()
    ]) { error in

        if let error = error {
            print("🔥 FIREBASE ERROR:")
            print(error.localizedDescription)
        } else {
            print("✅ FIREBASE CONNECTED SUCCESSFULLY")
        }
    }
}
