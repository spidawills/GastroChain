
### 📘 README for *GastroChain*

## 🚀 Key Features

* **Recipe Registration:** Chefs can register original recipes with metadata, difficulty level, cookbook references, and ingredient requirements.
* **License and Train:** Restaurants or learners can license a recipe, train with it, and certify mastery after a specified period.
* **Royalties and Compensation:** Upon certification, chefs receive a royalty payment tied to difficulty and ingredient usage.
* **Chef Reputation Index:** Chefs build a blockchain-based prestige score as more of their recipes are mastered.
* **Pantry Ledger:** Tracks the provisioning and consumption of ingredients for users and chefs.
* **Menu Lifecycle:** Recipes can be available, in training, mastered, or discontinued by their original creators.

---

## 📄 Smart Contract Structure

* `culinary-recipe-registry`: Maps recipe IDs to metadata and lifecycle info.
* `pantry-ledger`: Tracks user provisions (ingredients) used for licensing and certification.
* `chef-prestige-index`: Keeps score of chef achievements based on mastered recipes.
* `restaurant-menu-ledger`: Holds a history of up to 10 recipes per chef.

---

## 📚 Public Functions

### ✅ Recipe Registration

```clojure
(register-recipe ingredient-count royalty-rate training-period difficulty cookbook-ref flavor-profile)
```

Registers a new recipe with full metadata.

### ✅ License a Recipe

```clojure
(license-recipe recipe-id)
```

Allows a user to license and train with a recipe.

### ✅ Certify Mastery

```clojure
(certify-mastery recipe-id)
```

Confirms the successful mastery of a recipe after the training period and distributes royalties.

### ✅ Discontinue Recipe

```clojure
(discontinue-recipe recipe-id)
```

Removes a recipe from public availability by its head chef.

### ✅ Stock Provisions

```clojure
(stock-provisions quantity)
```

Adds ingredients to a user's pantry for future transactions.

---

## 🔍 Read-Only Functions

### View Recipe Details

```clojure
(query-recipe-details recipe-id)
```

### View User Pantry

```clojure
(view-pantry-inventory entity)
```

### View Chef Prestige Score

```clojure
(fetch-chef-reputation chef)
```

### List Menu Recipes

```clojure
(list-menu-items entity)
```

### Compute Difficulty Cost Multiplier

```clojure
(compute-difficulty-factor rating)
```

---

## 🧩 Error Codes

| Code | Meaning                            |
| ---- | ---------------------------------- |
| 201  | Access denied                      |
| 202  | Recipe already licensed            |
| 203  | Not enough ingredients             |
| 204  | Recipe not found                   |
| 205  | Training still in progress         |
| 206  | Invalid ingredient count           |
| 207  | Royalty out of bounds              |
| 208  | Invalid training duration          |
| 209  | Invalid recipe ID                  |
| 210  | Invalid difficulty rating          |
| 211  | Recipe is discontinued             |
| 212  | Provision quantity too small       |
| 213  | Cookbook reference missing         |
| 214  | Flavor profile description missing |

---

## 🛠️ Development Notes

* Written in [Clarity](https://docs.stacks.co/write-smart-contracts/clarity-language)
* Tested for Stack protocol compatibility
* Uses on-chain logic to ensure fair and transparent transactions

---

## 💡 Future Enhancements

* NFT integration for signature recipes
* Community upvoting or reviews
* Cross-chef collaboration support
* Marketplace interface for recipe discovery and licensing

---

## 👩‍🍳 Powered by Decentralized Creativity

**GastroChain** is where the art of cooking meets the integrity of blockchain. Preserve your culinary legacy—one recipe at a time.
