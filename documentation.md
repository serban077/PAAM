# SmartFitAI - Documentație Proiect PAAM

**Nume echipă:**
- [Nume Membru 1]
- [Nume Membru 2]

---

<br>

### 1. Introducere

**Ce?** - SmartFitAI este o aplicație mobilă modernă, bazată pe Flutter, concepută pentru a oferi utilizatorilor planuri personalizate de fitness și nutriție. Aplicația utilizează Inteligența Artificială pentru a genera rutine de antrenament și planuri de masă adaptate obiectivelor și preferințelor utilizatorului.

**De ce?** - Motivația din spatele SmartFitAI este de a acționa ca un asistent personal de fitness și nutriție, făcând un stil de viață sănătos mai accesibil și mai eficient prin personalizare bazată pe AI. Proiectul combină funcționalități din aplicații de top, adăugând o integrare mai profundă a AI-ului pentru a oferi o experiență superioară și unică. Îmbunătățirea constă în centralizarea planificării antrenamentelor și a nutriției într-un singur loc, cu recomandări inteligente care în mod normal ar necesita un antrenor personal.

<br>

### 2. State of the Art

Pentru a înțelege peisajul actual al aplicațiilor de fitness, am analizat două aplicații populare: **Fitbod** și **Freeletics**. Acestea reprezintă un punct de plecare excelent, iar SmartFitAI își propune să combine cele mai bune caracteristici ale lor și să le îmbunătățească prin intermediul AI-ului.

| Caracteristici | Fitbod | Freeletics | SmartFitAI |
| :--- | :---: | :---: | :---: |
| ***Store link*** | [Google Play](https://play.google.com/store/apps/details?id=com.fitbod.fitbod) | [Google Play](https://play.google.com/store/apps/details?id=com.freeletics.lite) | - |
| ***Store grade*** | 4.5 / 5 | 4.6 / 5 | - |
| ***Nr. installs*** | 1M+ | 10M+ | - |
| ***Nr. ratings*** | 48K | 358K | - |
| ***Ads/ in-app purchases*** | Da | Da | Nu |
| *Login/user* | Da | Da | Da |
| *Planuri de antrenament AI* | Da | Da | Da |
| *Planuri de nutriție AI* | Nu | Nu | Da |
| *Bibliotecă de exerciții*| Da | Da | Da |
| *Urmărirea progresului*| Da | Da | Da |
| *Gamification* | Nu | Da | Nu |

<br>

### 3. Design și Implementare

**Cum?** - SmartFitAI este construit folosind Flutter pentru frontend și Supabase pentru backend. Arhitectura este concepută pentru a fi modulară și scalabilă.

**Use Cases (Funcționalități):**
-   **Autentificare utilizator**: Login și signup securizat.
-   **Onboarding**: Un chestionar inițial pentru a colecta date despre utilizator (obiective, nivel de fitness, preferințe alimentare).
-   **Generare Plan AI**: Utilizatorii pot solicita un plan de antrenament sau de nutriție. O cerere este trimisă către un serviciu care interacționează cu Gemini AI pentru a genera un plan personalizat.
-   **Dashboard Principal**: Afișează planul zilnic, progresul și oferă acces la celelalte secțiuni.
-   **Biblioteca de Exerciții**: O listă de exerciții, fiecare cu detalii și instrucțiuni.
-   **Urmărirea Progresului**: Vizualizarea progresului în timp (greutate, măsurători, performanță).

**Arhitectură și Tehnologii:**
-   **Flutter & Dart**: Pentru dezvoltarea aplicației cross-platform.
-   **Supabase**: Backend-as-a-Service pentru baza de date (PostgreSQL), autentificare și funcții serverless.
-   **Gemini AI**: Modelul de limbaj pentru generarea planurilor.
-   **Sizer**: Pentru design responsiv.
-   **fl_chart**: Pentru afișarea graficelor de progres.
-   **Provider/Bloc**: (Menționați aici soluția de state management folosită) pentru managementul stării aplicației.

*[Aici se poate insera o diagramă UML a arhitecturii sau a principalelor cazuri de utilizare.]*

<br>

### 4. System Usage

Utilizarea principală a aplicației urmează un flux simplu și intuitiv:
1.  **Autentificare/Creare Cont**: Utilizatorul își crează un cont sau se autentifică.
2.  **Onboarding**: La prima autentificare, utilizatorul completează un chestionar pentru personalizarea experienței.
3.  **Dashboard**: Utilizatorul ajunge pe ecranul principal unde poate vedea antrenamentul și mesele pentru ziua curentă.
4.  **Generare Plan**: Din secțiunea dedicată, utilizatorul poate cere un nou plan de antrenament sau de nutriție, specificând preferințele.
5.  **Executare și Urmărire**: Utilizatorul urmează planul și înregistrează progresul (ex. greutăți ridicate, seturi, repetări, mese consumate).

*[Adaugă aici un screenshot reprezentativ al aplicației, de exemplu, Dashboard-ul principal.]*
**Fig. 1: Dashboard-ul principal al aplicației SmartFitAI**

<br>

### 5. Concluzii

Proiectul a reușit să integreze cu succes un model de AI (Gemini) într-o aplicație Flutter pentru a oferi planuri personalizate de fitness și nutriție. Procesul de dezvoltare a scos în evidență importanța unei structuri de proiect bine organizate și a unui backend scalabil precum Supabase.

**Ce am învățat?**
-   Integrarea serviciilor third-party (Supabase, Gemini) într-o aplicație Flutter.
-   Managementul stării într-o aplicație complexă.
-   Provocările legate de crearea unui design UI/UX intuitiv pentru o aplicație cu multiple funcționalități.

**Ce a fost greu?**
-   Gestionarea prompt-urilor pentru AI pentru a obține rezultate consistente și de înaltă calitate.
-   Asigurarea unei experiențe de utilizare fluide, în ciuda apelurilor asincrone către backend și AI.

**Ce ne-a plăcut?**
-   Libertatea de a alege tehnologiile și de a construi o aplicație de la zero.
-   Văzând cum o idee prinde viață și devine o aplicație funcțională.

<br>

### Referințe

[1] Fitbod. *Fitbod: Your Personal Trainer*, [https://play.google.com/store/apps/details?id=com.fitbod.fitbod](https://play.google.com/store/apps/details?id=com.fitbod.fitbod)

[2] Freeletics. *Freeletics: AI Personal Trainer*, [https://play.google.com/store/apps/details?id=com.freeletics.lite](https://play.google.com/store/apps/details?id=com.freeletics.lite)
