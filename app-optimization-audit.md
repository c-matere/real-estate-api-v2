# App Optimization & Page Consolidation Audit

**Last updated: 2025-05-14**

## 1. Repetitive Page Patterns

### 1.1 Entity CRUD Pages
- Tenant pages: `src/pages/Tenants/*` (list, details, forms)
- Unit pages: `src/pages/Units/*`
- TenantAssignment pages: `src/pages/TenantAssignments/*`
- Report pages: `src/pages/Reports/*`
- Finance pages: `src/pages/Finance/Income.js`, `Expenses.js`

_All these follow identical patterns:_
1. Fetch list of items
2. Display table with filters, sorting, pagination
3. Navigate to item detail or edit form
4. Render create/edit form with validation

### 1.2 Dashboard and Relationship Views
- Multiple dashboards (`Dashboard/index.js`, `Dashboard/RelationshipDashboard/index.js`)
- Similar widgets and KPI cards repeating across views

### 1.3 Navigation and Layout Components
- Sidebar, header, and page scaffolding repeated in each page component


## 2. Compression & Consolidation Strategies

### 2.1 Generic Entity Module
- **Implement a single `EntityPage`** component that takes props:
  - `entityName` (e.g., "tenant", "unit")
  - `config` (fields, endpoints from `Entities/entityConfig.js`)
- **Routes**: Use dynamic route segments `/app/:entity/:action(create|list|edit)/:id?`
- Eliminates duplicate pages for each entity

### 2.2 Shared Table & Form Components
- Create `<DataTable />` and `<EntityForm />` in `components/common`
- Accepts schema from `entityConfig` and handles API calls, validation, and UI

### 2.3 Unified Dashboard
- Merge similar dashboards into a single configurable dashboard
- Expose widget registry so pages can select relevant charts and lists

### 2.4 Tabbed Interfaces for Finance & Reports
- Combine `Income` and `Expenses` into one `/finance` page with tabs
- Combine multiple report pages under `/reports` with sub-tabs

### 2.5 Layout & Navigation Abstraction
- Extract header, sidebar, and breadcrumb logic into `Layout` component
- Wrap pages with `<Layout>` so scaffolding is defined once

### 2.6 Code-Splitting & Lazy Loading
- Lazy-load each `EntityPage` and major sections to reduce initial bundle


## 3. Quick Access Improvements
- **Global Search** bar for tenants, units, assignments
- **Quick Actions** dropdown in header for common tasks (add tenant, assign unit)
- **Keyboard Shortcuts** for power users (e.g., `Ctrl+I` to open tenant list)


## 4. Next Steps
1. Catalog all existing page files under `src/pages`
2. Define `entityConfig.js` entries for each data model
3. Build and test `EntityPage`, `<DataTable />`, `<EntityForm />`
4. Migrate one entity (e.g., `Tenant`) to new pattern as proof of concept
5. Iterate to cover all entities and finance/report pages

---
*End of audit.*
