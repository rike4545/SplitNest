# SplitNest localization

The app includes English (fallback), Spanish (`es`), French (`fr`), German (`de`), Brazilian Portuguese (`pt-BR`), and Japanese (`ja`). It follows the preferred app language chosen by iOS. No separate in-app language override is needed.

`SplitNest/Localizable.xcstrings` holds interface labels, validation messages, notification titles, expense categories, recurrence labels, and household insight replies. Keep stored enum raw values and user-entered names unchanged. String formats use whole sentences so translations can rearrange words. Count labels use plural variations. Dates use localized formatting; the household currency remains an independent persisted setting.

Household Insights offers translated topic buttons and a limited keyword vocabulary in all six languages. It remains a deterministic offline assistant. The buttons provide reliable access without depending on keyword recognition.

## Verification

Run `python3 scripts/validate_localizations.py` to check language coverage and format arguments. Run unit tests in Xcode to verify bundled localized resources and multilingual topic selection.

Before release, build and launch on an iPhone simulator for every language. In the scheme, choose Run > Options > App Language and App Region. Check narrow screens, large Dynamic Type, plural counts (0, 1, 2), add/edit expense validation, backup alerts, budget labels, and reminder notifications. Have native speakers review the wording, especially debt direction and financial labels. Translations have not yet had native-speaker review or simulator layout verification.

## App Store copy

Suggested localized subtitles and descriptions are below. These are repository copy drafts; they have not been uploaded to App Store Connect. Localized screenshots must be captured after simulator verification.

| Locale | Subtitle |
| --- | --- |
| es | Gastos y tareas compartidos |
| fr | Dépenses et tâches partagées |
| de | Ausgaben und Aufgaben teilen |
| pt-BR | Despesas e tarefas da casa |
| ja | 支出と家事をみんなで管理 |

### Español

Organiza los gastos, las tareas y las listas de tu casa con SplitNest. Registra compras compartidas, consulta quién debe a quién y define presupuestos mensuales por categoría. Revisa los próximos vencimientos, activa recordatorios y exporta una copia de seguridad de tus datos. Los datos de la casa y los resúmenes se guardan en tu dispositivo.

### Français

Organisez les dépenses, les tâches et les listes de votre foyer avec SplitNest. Enregistrez les achats partagés, consultez qui doit de l’argent à qui et définissez des budgets mensuels par catégorie. Suivez les prochaines échéances, activez les rappels et exportez une sauvegarde de vos données. Les données du foyer et les résumés restent sur votre appareil.

### Deutsch

Organisiere die Ausgaben, Aufgaben und Listen deines Haushalts mit SplitNest. Erfasse gemeinsame Einkäufe, sieh nach, wer wem Geld schuldet, und lege monatliche Kategoriebudgets fest. Behalte anstehende Fälligkeiten im Blick, aktiviere Erinnerungen und exportiere eine Datensicherung. Haushaltsdaten und Zusammenfassungen bleiben auf deinem Gerät.

### Português do Brasil

Organize as despesas, tarefas e listas da sua casa com o SplitNest. Registre compras compartilhadas, veja quem deve a quem e defina orçamentos mensais por categoria. Acompanhe os próximos vencimentos, ative lembretes e exporte um backup dos seus dados. Os dados da casa e os resumos ficam no seu dispositivo.

### 日本語

SplitNestで、家の支出、家事、リストを管理しましょう。共有の買い物を記録し、誰が誰に支払うかを確認して、カテゴリーごとの月間予算を設定できます。今後の期限を確認し、リマインダーを有効にして、データのバックアップを書き出せます。世帯データと要約は端末内に保存されます。
