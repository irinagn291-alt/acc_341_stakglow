import SwiftUI

enum PeopleFocus: Hashable {
    case newName
    case homeClub
    case awayClub
}

/// Names on this phone, plus the fields that add another person.
struct TipsterEditor: View {
    @Bindable var desk: BoardDesk
    @Binding var newName: String
    @FocusState.Binding var focus: PeopleFocus?

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s4) {
            Text("People on this phone")
                .font(TypeScale.body.weight(.semibold))
                .foregroundStyle(DesignTokens.ink)
            if desk.board.tipsters.isEmpty {
                Text("Add the first person, then punch a match together.")
                    .font(TypeScale.body)
                    .foregroundStyle(DesignTokens.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            ForEach(desk.board.tipsters) { person in
                PersonNameField(desk: desk, person: person)
            }
            TextField(
                "",
                text: $newName,
                prompt: Text("New name").foregroundStyle(DesignTokens.muted)
            )
            .font(TypeScale.body)
            .foregroundStyle(DesignTokens.ink)
            .textInputAutocapitalization(.words)
            .focused($focus, equals: .newName)
            .submitLabel(.next)
            .onSubmit { focus = .homeClub }
            .padding(.horizontal, Spacing.s3)
            .frame(minHeight: HitTarget.min)
            .hairlineFill(radius: Radius.chip)
            Button("Add person") {
                desk.addTipster(name: newName)
                if desk.refusal == nil {
                    newName = ""
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(newName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .id("people")
    }
}

private struct PersonNameField: View {
    var desk: BoardDesk
    let person: Tipster
    @State private var name: String

    init(desk: BoardDesk, person: Tipster) {
        self.desk = desk
        self.person = person
        _name = State(initialValue: person.name)
    }

    var body: some View {
        TextField(
            "",
            text: $name,
            prompt: Text("Name").foregroundStyle(DesignTokens.muted)
        )
        .font(TypeScale.body)
        .foregroundStyle(DesignTokens.ink)
        .textInputAutocapitalization(.words)
        .padding(.horizontal, Spacing.s3)
        .frame(minHeight: HitTarget.min)
        .hairlineFill(radius: Radius.chip)
        .onChange(of: name) { _, newValue in
            let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty, trimmed != person.name else { return }
            desk.renameTipster(id: person.id, name: trimmed)
        }
        .onChange(of: person.name) { _, newValue in
            if name != newValue {
                name = newValue
            }
        }
    }
}
