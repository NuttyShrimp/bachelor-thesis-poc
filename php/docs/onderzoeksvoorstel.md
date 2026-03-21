# Onderzoeksvoorstel Bachelorproef

## Titel

**Performance-analyse van server-side Swift versus PHP voor CPU-intensieve backend operaties: een case study bij BakerOnline**

---

## Academiejaar

2024-2025

## Student

- **Naam:** Jan Lecoutere
- **Opleiding:** Toegepaste Informatica
- **Specialisatie:** Mobile & Enterprise Developer
- **Campus:** HOGENT Gent

## Stagebedrijf / Co-promotor

- **Bedrijf:** BakerOnline
- **Co-promotor:** Ben Serlippens
- **Contact:** ben@bakeronline.com

---

## 1. Probleemstelling

### Context

PHP is de dominante taal voor webontwikkeling en vormt de basis van frameworks zoals Laravel, dat wereldwijd wordt ingezet voor enterprise applicaties. Ondanks optimalisaties zoals OPcache en de introductie van JIT-compilatie in PHP 8, blijft PHP een geïnterpreteerde taal met inherente performance-overhead bij elke request.

BakerOnline is een Belgisch e-commerce platform voor bakkerijen met meer dan 500 aangesloten winkels. Het platform verwerkt dagelijks duizenden bestellingen en genereert CPU-intensieve outputs zoals:

- **Productielijsten** (Excel-exports met O(n⁵) complexiteit door geneste loops)
- **Bulk PDF-facturen** (sequentiële generatie van 100+ documenten)
- **JSON-transformaties** (complexe DTO-mapping voor API responses)
- **BTW-berekeningen** (geneste iteraties over bestellingen met opties)

Deze operaties vormen een bottleneck in de huidige PHP/Laravel architectuur.

### Het probleem

Server-side Swift, met frameworks zoals Vapor en Hummingbird, biedt potentieel significante performanceverbeteringen door:

1. **Ahead-of-time compilatie** naar native machine code
2. **Efficiënt geheugenbeheer** via Automatic Reference Counting (ARC) met value types
3. **Native parallellisme** via async/await en structured concurrency
4. **Geoptimaliseerde datastructuren** (structs vs PHP arrays)

De vraag rijst of migratie van specifieke CPU-intensieve operaties naar Swift een rendabele investering is voor enterprise PHP-applicaties.

---

## 2. Onderzoeksvraag

### Hoofdvraag

> **In welke mate kan server-side Swift de uitvoeringstijd verbeteren voor CPU-intensieve backend operaties in vergelijking met traditioneel PHP-FPM en Laravel Octane?**

### Deelvragen

1. **Hoe presteren PHP-FPM, Laravel Octane (FrankenPHP/Swoole) en Swift/Vapor voor geïsoleerde CPU-bound operaties?**
   - DTO/JSON mapping (de kern van moderne API-architectuur)
   - Wiskundige berekeningen (BTW, winkelwagen-totalen)
   - Bestandsgeneratie (Excel, PDF)

2. **Welke operatietypes profiteren het meest van Swift's compiled nature?**
   - Pure computatie vs I/O-bound operaties
   - Kleine vs grote datasets
   - Enkelvoudige vs batch-verwerking

3. **Wat is de impact van Laravel Octane als tussenoplossing?**
   - Vergelijking PHP-FPM → Octane → Swift
   - Warm request performance vs cold start

4. **Wat zijn de praktische overwegingen voor een hybride architectuur?**
   - Development complexity
   - Deployment en operationele overhead
   - Wanneer is Swift-migratie rendabel?

---

## 3. Literatuurstudie (State of the Art)

### 3.1 PHP Performance Evolutie

PHP heeft significante performanceverbeteringen doorgemaakt:

- **PHP 7.0 (2015):** Nieuwe Zend Engine 3.0, 2x sneller dan PHP 5.6
- **PHP 8.0 (2020):** JIT-compilatie, union types, named arguments
- **PHP 8.3 (2023):** Verdere JIT-optimalisaties, readonly classes

Desondanks blijft PHP request-gebaseerd met per-request bootstrapping overhead.

### 3.2 Laravel Octane

Laravel Octane (2021) adresseert de bootstrapping-overhead door de applicatie in geheugen te houden tussen requests:

- **FrankenPHP:** Moderne PHP application server gebouwd op Caddy
- **Swoole:** Coroutine-based async PHP runtime
- **RoadRunner:** Go-based PHP application server

Octane elimineert cold-start overhead maar verandert niet de fundamentele PHP runtime karakteristieken.

### 3.3 Server-side Swift

Swift, ontwikkeld door Apple (2014, open-source sinds 2015), heeft zich ontwikkeld tot een volwaardig server-side ecosysteem:

- **Vapor:** Meest populaire Swift web framework
- **Hummingbird:** Lichtgewicht alternatief
- **Swift NIO:** Non-blocking I/O foundation

Bestaande benchmarks (TechEmpower, various GitHub projects) suggereren 5-20x speedups voor specifieke operaties, maar gecontroleerde vergelijkingen met realistische enterprise workloads zijn schaars.

### 3.4 Kennislacune

Er bestaat beperkt academisch onderzoek naar:

1. Performance vergelijking met **realistische enterprise data** (niet synthetische benchmarks)
2. Specifieke analyse van **DTO-mapping overhead** (JSON → typed objects)
3. Vergelijking inclusief **Laravel Octane** als middenweg
4. Praktische **migratiestrategie** voor hybride architecturen

Dit onderzoek adresseert deze lacune met een concrete case study.

---

## 4. Methodologie

### 4.1 Onderzoeksaanpak

Dit onderzoek volgt een **experimentele kwantitatieve methode** met gecontroleerde benchmarks.

### 4.2 Benchmark Isolatie

Om een zuivere vergelijking te maken tussen runtime performance worden de benchmark operaties **geïsoleerd van externe factoren**:

- **Geen database queries:** Productiedata wordt geëxporteerd naar statische JSON-bestanden
- **Geen netwerk latency:** Lokale uitvoering op identieke hardware
- **Identieke datasets:** Exact dezelfde JSON-input voor alle implementaties
- **Identieke algoritmes:** Functioneel equivalente implementaties

Deze aanpak is standaard voor performance research en garandeert dat **alleen de taal-runtime** wordt gemeten.

### 4.3 Test Operaties

Gebaseerd op analyse van het BakerOnline platform werden de volgende CPU-intensieve operaties geïmplementeerd:

| Operatie | Complexiteit | Beschrijving |
|----------|--------------|--------------|
| **DTO Mapping** | O(n × d) | JSON naar typed objects (kern van API's) |
| **BTW Berekening** | O(n × m) | Bestellingen × producten × opties |
| **Winkelwagen Berekening** | O(n × m) | Prijsberekening met kortingen |
| **JSON Transformatie** | O(c × p) | Shop data naar API response |
| **Excel Generatie** | O(n⁵) | Productielijst met styling |
| **PDF Generatie** | O(n) | Factuur rendering (hoge constante) |

### 4.4 Test Configuraties

Drie configuraties worden vergeleken:

1. **PHP-FPM:** Standaard Laravel deployment
2. **Laravel Octane:** Met FrankenPHP of Swoole
3. **Swift/Vapor:** Native Swift implementatie

### 4.5 Metrieken

Per operatie worden gemeten:

- **Execution time** (ms): Gemiddelde, min, max
- **P95/P99 latency:** Tail latency voor productie-relevantie
- **Memory usage** (MB): Piek geheugengebruik
- **Throughput:** Operaties per seconde

### 4.6 Statistische Validatie

- Minimum **100 iteraties** per benchmark (meer voor snelle operaties)
- **Warm-up runs** om JIT/cache effecten te stabiliseren
- Berekening van **standaarddeviatie** en betrouwbaarheidsintervallen

### 4.7 Hardware

Benchmarks worden uitgevoerd op identieke hardware:
- Apple Silicon (M1/M2/M3) of Intel-based systeem
- Geïsoleerde omgeving (geen achtergrondprocessen)
- Consistente OS configuratie

---

## 5. Verwachte Resultaten

### 5.1 Hypotheses

Gebaseerd op literatuur en de karakteristieken van de operaties:

| Operatie | PHP-FPM | Octane | Swift | Verwachte Verbetering |
|----------|---------|--------|-------|----------------------|
| DTO Mapping | Baseline | -20% | -90% | **10x** (hoogste impact) |
| BTW Berekening | Baseline | -20% | -95% | **20x** |
| JSON Transformatie | Baseline | -60% | -90% | **10x** |
| Excel Generatie | Baseline | -25% | -70% | **3-5x** |
| PDF Generatie | Baseline | -20% | -50% | **2x** (I/O bound) |

### 5.2 Verwachte Conclusies

1. **Swift biedt significante speedups voor pure computatie** (10-20x voor DTO mapping, berekeningen)

2. **I/O-bound operaties profiteren minder** (PDF, Excel met file I/O)

3. **Octane is een waardevolle tussenoplossing** die 20-60% verbetering biedt zonder taalwissel

4. **Hybride architectuur is optimaal:** Swift voor CPU-intensieve microservices, PHP voor CRUD en business logic

---

## 6. Casus: BakerOnline

### 6.1 Over BakerOnline

BakerOnline is een Belgisch e-commerce platform gespecialiseerd in online besteloplossingen voor bakkerijen. Het platform:

- Bedient **500+ bakkerijen** in België
- Verwerkt **duizenden bestellingen per dag**
- Beheert **complexe productcatalogi** met opties, allergenen, prijsregels
- Genereert **dagelijkse productielijsten en facturen**

### 6.2 Technische Stack

- **Backend:** PHP 8.x, Laravel 10.x
- **Database:** MySQL/MariaDB
- **Architecture:** Domain-Driven Design met 50+ componenten
- **Data complexiteit:** Producten met geneste JSON (settings, translations, stock)

### 6.3 Geïdentificeerde Bottlenecks

Uit analyse van de codebase werden de meest CPU-intensieve operaties geïdentificeerd:

1. `GetProductionListExcelWriterAction` - 5 geneste foreach loops
2. `GenerateZipWithInvoicesAction` - Sequentiële PDF generatie
3. `VatCalculator` - Complexe BTW berekeningen
4. `ExtendedShopTransformer` - Diepe JSON transformaties
5. **DTO Mapping** - JSON decode → typed objects overhead

### 6.4 Data Export

Voor reproduceerbare benchmarks werd productiedata geëxporteerd:

| Bestand | Grootte | Inhoud |
|---------|---------|--------|
| `products.json` | 52 MB | 500 producten met settings_json, translations_json |
| `orders.json` | 24 MB | 200 bestellingen met geneste products_json |
| `shop.json` | 1 MB | Shop met categorieën en producten |
| `cart_scenarios.json` | 733 KB | 4 scenario's (3, 10, 50, 200 items) |

---

## 7. Planning

| Fase | Periode | Activiteiten |
|------|---------|--------------|
| **1. Voorbereiding** | Jan - Feb 2025 | Literatuurstudie, onderzoeksvoorstel |
| **2. PHP Benchmarks** | Feb - Mrt 2025 | PHP-FPM en Octane metingen |
| **3. Swift Implementatie** | Mrt - Apr 2025 | Vapor project, equivalente operaties |
| **4. Swift Benchmarks** | Apr 2025 | Metingen en vergelijking |
| **5. Analyse** | Apr - Mei 2025 | Statistische analyse, conclusies |
| **6. Scriptie** | Mei - Jun 2025 | Schrijven en revisie |
| **7. Verdediging** | Jun 2025 | Presentatie |

---

## 8. Referenties

### Academisch

- Nanz, S., & Furia, C. A. (2015). A comparative study of programming languages in Rosetta Code. *IEEE/ACM ICSE*.
- Prechelt, L. (2000). An empirical comparison of seven programming languages. *IEEE Computer*.

### Technisch

- Laravel Documentation. (2024). Laravel Octane. https://laravel.com/docs/octane
- Vapor Documentation. (2024). Vapor Framework. https://docs.vapor.codes
- PHP Documentation. (2024). PHP 8.x Performance. https://www.php.net/releases/8.0/
- Apple Inc. (2024). Swift.org. https://swift.org

### Benchmarks

- TechEmpower Web Framework Benchmarks. https://www.techempower.com/benchmarks/
- The Benchmarks Game. https://benchmarksgame-team.pages.debian.net/benchmarksgame/

---

## 9. Bijlagen

### A. Repository Structuur

```
bachelorproef/jan/
├── app/
│   └── Benchmarks/
│       ├── BenchmarkRunner.php
│       ├── DataLoader.php
│       ├── Dtos/
│       └── Operations/
│           ├── VatCalculation.php
│           ├── CartCalculation.php
│           ├── JsonTransformation.php
│           ├── ExcelGeneration.php
│           ├── PdfGeneration.php
│           └── DtoMapping.php
├── data/
│   ├── products.json
│   ├── orders.json
│   ├── shop.json
│   └── cart_scenarios.json
└── routes/
    └── benchmark.php
```

### B. Voorbeeld Benchmark Output

```json
{
  "meta": {
    "php_version": "8.3.0",
    "runtime_mode": "php-fpm",
    "timestamp": "2024-12-02T10:00:00+01:00"
  },
  "benchmarks": {
    "dto_mapping": {
      "avg_time_ms": 45.234,
      "p95_time_ms": 52.100,
      "p99_time_ms": 58.450,
      "memory_used_mb": 12.5
    }
  }
}
```

---

*Dit onderzoeksvoorstel werd opgesteld in samenwerking met BakerOnline als casus-bedrijf.*
