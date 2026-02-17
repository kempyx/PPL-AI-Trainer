import SwiftUI

struct ExamDatePickerView: View {
    @Binding var examDateLeg1: Date?
    @Binding var examDateLeg2: Date?
    @Binding var examDateLeg3: Date?
    let onContinue: () -> Void
    
    private let legs: [(title: String, subjects: String)] = [
        ("Leg 1 – Technical & Legal", "AGK · PoF · Air Law"),
        ("Leg 2 – Human & Environment", "Met · HPL · Comms"),
        ("Leg 3 – Planning & Navigation", "Nav · FPP · Ops")
    ]
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 50))
                .foregroundStyle(.orange)
            
            Text("When are your exams?")
                .font(.title.weight(.bold))
            
            Text("Swedish PPL exams are split into 3 legs (optional)")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            ScrollView {
                VStack(spacing: 12) {
                    legRow(title: legs[0].title, subjects: legs[0].subjects, date: $examDateLeg1)
                    legRow(title: legs[1].title, subjects: legs[1].subjects, date: $examDateLeg2)
                    legRow(title: legs[2].title, subjects: legs[2].subjects, date: $examDateLeg3)
                }
            }
            
            Spacer()
            
            Button {
                onContinue()
            } label: {
                Text("Continue")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(14)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 48)
        }
        .padding()
    }
    
    private func legRow(title: String, subjects: String, date: Binding<Date?>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.headline)
                    Text(subjects).font(.caption).foregroundColor(.secondary)
                }
                Spacer()
                if date.wrappedValue != nil {
                    Button {
                        date.wrappedValue = nil
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            if let unwrappedDate = Binding(date) {
                DatePicker("Date", selection: unwrappedDate, in: Date()..., displayedComponents: .date)
                    .datePickerStyle(.compact)
            } else {
                Button {
                    date.wrappedValue = Calendar.current.date(byAdding: .month, value: 3, to: Date())
                } label: {
                    HStack {
                        Image(systemName: "plus.circle")
                        Text("Set exam date")
                    }
                    .font(.subheadline)
                    .foregroundStyle(.blue)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial)
        .cornerRadius(14)
    }
}
