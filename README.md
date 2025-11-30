# chillIPTV

Benvenuti in **chillIPTV**! 📺🇮🇹

Questa repository nasce come fork/continuazione del progetto [IPTV-Italia di Tundrak](https://github.com/Tundrak/IPTV-Italia), con l'obiettivo di mantenere una lista di canali TV e Radio italiani costantemente aggiornata e funzionante.

## 🎯 Obiettivo
L'obiettivo principale è fornire file `.m3u` affidabili per la visione di canali italiani (TV e Radio) attraverso qualsiasi player IPTV. Ci impegniamo a verificare periodicamente i link e a sostituire quelli non funzionanti.

## 📂 Contenuto della Repository

Troverai i seguenti file principali:

| File | Descrizione |
|------|-------------|
| **`iptvitaplus.m3u`** | Lista completa con loghi, gruppi e canali locali (**consigliata**) |
| **`iptvita.m3u`** | Lista base dei canali TV italiani |
| **`ipradioita.m3u`** | Lista delle stazioni radio italiane |

## 📺 Struttura dei Canali

I canali sono organizzati per **numero LCN** (Logical Channel Number) del Digitale Terrestre italiano:

- **Canali 1-99**: Canali nazionali (Rai, Mediaset, Discovery, Sky, La7, ecc.)
- **Canali 100-899**: Radio e canali tematici
- **Canali 500+**: **Fallback** (link alternativi)

### 🔄 Canali Fallback (500+)

Per garantire maggiore affidabilità, abbiamo aggiunto una sezione **Fallback** con link alternativi per i canali principali. Questi utilizzano CDN diverse (NetPlus, CloudFront, Akamai, ecc.) e possono essere utili quando il link principale non funziona.

**Schema numerazione Fallback:** `500 + numero canale originale`

| Canale Originale | Numero | Fallback | Numero |
|-----------------|--------|----------|--------|
| Rai 1 | 1 | Rai 1 (NetPlus) | 501 |
| Rai 2 | 2 | Rai 2 (ilglobo) | 502 |
| Rai 3 | 3 | Rai 3 (NetPlus) | 503 |
| TV8 | 8 | TV8 (Sky CDN) | 508 |
| NOVE | 9 | NOVE (CloudFront) | 509 |
| ... | ... | ... | ... |

### 📍 Canali Locali (Emilia-Romagna)

La lista include anche canali locali della regione Emilia-Romagna:
- ETV, 7Gold, Teleromagna, 12 TV Parma, Icaro TV, TV Qui, Telestense, Teletricolore

## 🤝 Come Contribuire

**Il tuo aiuto è fondamentale!** Chiunque voglia contribuire è il benvenuto.

Se trovi un canale che non funziona o conosci un nuovo link ufficiale funzionante:
1.  Fai un **Fork** di questa repository.
2.  Modifica il file `.m3u` correggendo il link o aggiungendo il nuovo canale.
3.  Apri una **Pull Request (PR)** verso il branch `main` di questa repository.

**Nota:** Le PR con link testati e funzionanti saranno unite (merged) al più presto. Cerchiamo di mantenere la lista pulita e accessibile a tutti.

## 🚀 Come usare le liste

Puoi usare i link **Raw** di GitHub direttamente nel tuo player IPTV preferito:

**Link diretti (sempre aggiornati):**
```
https://raw.githubusercontent.com/chillFil/chillIPTV/main/iptvitaplus.m3u
https://raw.githubusercontent.com/chillFil/chillIPTV/main/iptvita.m3u
https://raw.githubusercontent.com/chillFil/chillIPTV/main/ipradioita.m3u
```

**Player compatibili:** VLC, PotPlayer, Kodi, IPTV Smarters, TiviMate, app per Smart TV, ecc.

## 🔧 Verifica qualità degli stream


Abbiamo aggiunto uno script PowerShell che permette di testare gli stream (HEAD/GET, ricerca master playlist, test con ffprobe/ffmpeg se disponibili):

- Script: `scripts/check_streams.ps1`
- Output: `stream_test_results_YYYYMMDD_HHMMSS.csv` (default, con timestamp)

Dipendenze consigliate (opzionali): `ffprobe` e `ffmpeg` nel `PATH` per ispezioni più precise.

Esempio di utilizzo:

```powershell
.\scripts\check_streams.ps1 -Urls 'URL1','URL2'
```

## 📋 Attributi M3U

I canali utilizzano i seguenti attributi standard:

| Attributo | Descrizione | Esempio |
|-----------|-------------|---------|
| `tvg-id` | ID per EPG (guida programmi) | `Rai1.it` |
| `tvg-chno` | Numero canale LCN | `1` |
| `tvg-logo` | URL del logo | `https://...` |
| `group-title` | Gruppo/categoria | `Rai`, `Mediaset`, `Locali` |

## 📜 Licenza e Disclaimer

Questa repository è fornita solo a scopo informativo e didattico. I link sono pubblicamente disponibili su Internet. Non ospitiamo alcun contenuto, ma forniamo solo collegamenti a stream già esistenti.

*Grazie a Tundrak per il lavoro originale su cui si basa questo progetto.*
