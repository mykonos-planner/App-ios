# Atelier

App per iPad per gestire il guardaroba e comporre outfit, **completamente offline**.

- Armadio con foto scattate dall'iPad o importate dalla libreria, colore rilevato automaticamente dalla foto.
- Outfit componibili, salvabili e riapribili.
- Motore di stile locale: punteggio 0–100 basato sull'armonia dei colori (neutri, analoghi, complementari, monocromatici) più la coerenza dei capi (occasione, fantasie, stagioni, completezza).
- Consigli: dato un capo, propone i capi dell'armadio che si abbinano meglio e i **colori** che funzionano (es. jeans blu chiaro → maglia bianca, nera, beige).
- Idee pronte: combina l'armadio e mostra le combinazioni con il punteggio più alto.

Nessuna chiamata di rete nel codice: foto, outfit e punteggi restano sul dispositivo.

## Come si ottiene l'IPA

Il progetto è un'app SwiftUI generata con [XcodeGen](https://github.com/yonaskolb/XcodeGen); la compilazione avviene su GitHub Actions (macOS), quindi non serve un Mac.

1. Crea un repository **privato** su GitHub chiamato `atelier-wardrobe`.
2. Carica questa cartella nel repository (branch `main`).
3. Vai in **Actions → Build IPA → Run workflow** (parte anche da solo al primo push).

Al termine il workflow pubblica una Release con il file **`Atelier.ipa`** (non firmato): scaricalo da *Releases* oppure dagli artifact della run.

## Come si installa sull'iPad

Apple richiede una firma per installare un'app: l'IPA prodotto qui è volutamente non firmato e va firmato con il tuo Apple ID.

1. Installa [Sideloadly](https://sideloadly.io) sul computer (Windows va bene) oppure [AltStore](https://altstore.io).
2. Collega l'iPad, trascina `Atelier.ipa` in Sideloadly, inserisci il tuo Apple ID e avvia.
3. Sull'iPad: **Impostazioni → Generali → VPN e gestione dispositivo** → autorizza lo sviluppatore, poi apri l'app.

Con un Apple ID gratuito la firma dura **7 giorni** (poi si ripete il procedimento); con un account Apple Developer a pagamento dura un anno.

## Struttura

```
project.yml                  # specifica XcodeGen (target iOS 16+)
Sources/AtelierApp.swift     # entry point
Sources/Models/              # capi, outfit, categorie
Sources/Core/                # colori, motore di stile, persistenza, foto
Sources/Design/              # palette, tipografia, componenti
Sources/Views/               # armadio, outfit, consigli
.github/workflows/build.yml  # build dell'IPA su macOS
```

Per aprire il progetto in Xcode serve macOS: `brew install xcodegen && xcodegen generate`.
