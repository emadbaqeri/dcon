src/
├── main.rs              # Entry point, CLI setup
├── lib.rs               # Library exports
├── cli/
│   ├── mod.rs           # CLI module exports
│   ├── commands.rs      # Command definitions
│   ├── args.rs          # Argument parsing
│   └── output.rs        # Output formatting
├── db/
│   ├── mod.rs           # Database module exports
│   ├── client.rs        # PostgreSQL client wrapper
│   ├── connection.rs    # Connection management
│   └── operations.rs    # CRUD operations
├── models/
│   ├── mod.rs           # Model exports
│   ├── database.rs      # Database-related structs
│   └── table.rs         # Table-related structs
└── utils/
    ├── mod.rs           # Utility exports
    ├── formatter.rs     # Output formatting utilities
    └── error.rs         # Custom error types
