# **App Name**: Jan Aushadhi Dharwad

## Core Features:

- Firestore Integration: Connects to Firestore to read medicine data from 'medicine-1' (MARG) and 'medicine-2' (PMBI) collections.
- Data Parsing & Display: Parses data from Firestore, handles different field names (e.g., 'MRP' vs 'M.R.P.'), and displays the medicine information in a user-friendly format.
- Tabbed Interface: Provides a tabbed interface to switch between 'Medicine-1 (MARG)' and 'Medicine-2 (PMBI)' datasets.
- Search Functionality: Implements a search bar on each tab to filter the list of medicines by name (Product Name/Drug Name) on the client side.
- Splash Screen with Loading: Displays a splash screen with the app logo, title, and a loading spinner while fetching data from Firestore.
- Error Handling: Handles errors during Firestore data loading and provides a retry option on the splash screen.

## Style Guidelines:

- Primary color: Deep Blue (#3F51B5) for a professional and trustworthy feel.
- Background color: Light Gray (#F0F4F7) for a clean and modern look.
- Accent color: Teal (#009688) to provide visual interest.
- Body and headline font: 'PT Sans' for a modern look.
- Use material design icons for a consistent and intuitive user experience.
- Use a card-based layout for displaying medicine information in the list views.
- Subtle fade-in animations when loading data or transitioning between tabs.