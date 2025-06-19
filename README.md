# Σχεδίαση και Υλοποίηση Αποθήκης Δεδομένων με βάση το Instacart Dataset

## Περιγραφή
Αντικείμενο αυτού του project ήταν η πλήρης σχεδίαση και υλοποίηση μιας **Αποθήκης Δεδομένων** και ενός **OLAP κύβου**, βασισμένων σε πραγματικά δεδομένα αγορών χρηστών από την πλατφόρμα **Instacart**.

## Αντικείμενο και Στόχοι

Το project περιλαμβάνει:
- Φόρτωση και καθαρισμό raw δεδομένων από CSV σε SQL Server
- Σχεδίαση πολυδιάστατου μοντέλου με **σχήμα αστέρα**
- Δημιουργία OLAP κύβου με **SQL Server Analysis Services (SSAS)**
- Εκτέλεση αναλύσεων με **MDX queries**
- Εξαγωγή **κανόνων συσχέτισης (association rules)** με Python και Apriori

## Περιεχόμενα του Φακέλου

```bash
eb_instacart_datawarehouse_full_setup.sql        -- SQL script: από raw δεδομένα σε star schema
eb_instacart_olap_cube_queries.mdx              -- MDX queries πάνω στον κύβο
instacart_apriori_association_rules.py          -- Python script για Apriori & visualization
eb_DataWarehouse.zip                            -- Ολόκληρο το Visual Studio SSAS project (cube, dim, dsv κλπ.)
````

---

## Τεχνολογίες που Χρησιμοποιήθηκαν

* **SQL Server 2019**
* **SQL Server Analysis Services (SSAS)**
* **Visual Studio 2019**
* **MDX** για πολυδιάστατα ερωτήματα
* **Python (pandas, mlxtend)** για εξόρυξη κανόνων
* **Excel** για Pivot Tables και γραφήματα

---

## Σχεδίαση Σχήματος Αστέρα

Κεντρικός πίνακας γεγονότων: `FactOrders`
Διαστάσεις:

* `DimProduct`: προϊόντα, ιεραρχία department → aisle → product
* `DimTime`: part of day + day of week
* `DimUser`: loyalty segmentation (frequent, regular, rare + reorder profile)

Όλες οι σχέσεις υλοποιούνται με primary/foreign keys και ευρετήρια για βέλτιστη απόδοση.

![eb_cubes](https://github.com/user-attachments/assets/58480b79-ed07-4b37-9ca4-3a90e40bc969)


## Οδηγίες Εκτέλεσης

### Εισαγωγή Δεδομένων στη Βάση

* Άνοιξτε το SQL Server Management Studio
* Εκτέλεστε το `eb_instacart_datawarehouse_full_setup.sql`
* Το script:

  * Δημιουργεί τους raw πίνακες και φορτώνει τα δεδομένα (μέσω `BULK INSERT`)
  * Ελέγχει τα δεδομένα και φτιάχνει τους πίνακες Dim/Fact
  * Ορίζει indexes, constraints και κλειδιά

📌 *Τα CSV αρχεία δεν περιλαμβάνονται στο zip λόγω μεγέθους. Κατεβάστε τα από:
[https://www.kaggle.com/datasets/psparks/instacart-market-basket-analysis](https://www.kaggle.com/datasets/psparks/instacart-market-basket-analysis)*

> Προσαρμόστε τα paths στο SQL script (π.χ. `C:\Temp\instacart\orders.csv`) ανάλογα με το δικό σας περιβάλλον.

---

### Υλοποίηση και Περιήγηση στον OLAP Κύβο

* Άνοιξτε το αρχείο `eb_Instacart.sln` με το Visual Studio (με SSAS Extension)
* Κάνετε **Deploy** και **Process** τον κύβο στον Analysis Services Server
* Περιηγηθείτε στον κύβο μέσω:

  * του **Browser tab** του Visual Studio
  * ή **Excel Pivot Reports**

### Εκτέλεση MDX Ερωτημάτων

* Άνοιξτε το `eb_instacart_olap_cube_queries.mdx` στο SSAS Query Editor
* Τα queries περιλαμβάνουν:

  * Orders ανά κατηγορία χρήστη και ώρα/μέρα
  * Μέσο καλάθι ανά loyalty profile
  * Top time slots και aisles

### Εξαγωγή Κανόνων Συσχέτισης

* Τρέξτε το script `instacart_apriori_association_rules.py`
* Το script:

  * Δημιουργεί ένα δείγμα basket matrix από την SQL βάση
  * Εφαρμόζει τον αλγόριθμο **Apriori**
  * Φιλτράρει τους κανόνες με βάση support, confidence και lift
  * Οπτικοποιεί τους top 5 κανόνες
 
 ### Εγκατάσταση απαιτούμενων πακέτων
Το script `instacart_apriori_association_rules.py` απαιτεί τα παρακάτω πακέτα:

```bash
pip install -r requirements.txt

>*Αναπτύχθηκε αποκλειστικά για εκπαιδευτικούς σκοπούς.*
