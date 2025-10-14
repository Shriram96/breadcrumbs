# Breadcrumbs Presentation Diagrams
## Mermaid Diagrams for Presentation

### Diagram 1: System Architecture Overview (Slide 8)
**4-Layer Architecture Design**

```mermaid
graph TB
    subgraph "Presentation Layer"
        CV[ContentView]
        ChatV[ChatView]
        SV[SettingsView]
        SSV[ServerSettingsView]
    end
    
    subgraph "Business Logic Layer"
        CVM[ChatViewModel]
        SM[ServiceManager]
        TR[ToolRegistry]
    end
    
    subgraph "Data Access Layer"
        AIM[AIModel Protocol]
        OAI[OpenAIModel]
        KP[KeychainProtocol]
        KH[KeychainHelper]
    end
    
    subgraph "System Integration Layer"
        VT[VPNDetectorTool]
        DT[DNSReachabilityTool]
        AT[AppCheckerTool]
        ST[SystemDiagnosticTool]
        VS[VaporServer]
    end
    
    CV --> CVM
    ChatV --> CVM
    SV --> KH
    SSV --> SM
    
    CVM --> AIM
    CVM --> TR
    SM --> VS
    SM --> AIM
    
    AIM --> OAI
    KP --> KH
    
    TR --> VT
    TR --> DT
    TR --> AT
    TR --> ST
    
    VS --> AIM
    VS --> TR
```

### Diagram 2: Tool Execution Flow (Slide 9)
**AI-Driven Diagnostic Process**

```mermaid
sequenceDiagram
    participant U as User
    participant CV as ChatView
    participant CVM as ChatViewModel
    participant AI as AIModel
    participant TR as ToolRegistry
    participant T as Tool
    participant S as System
    
    U->>CV: Ask question
    CV->>CVM: sendMessage()
    CVM->>AI: sendMessage(messages, tools)
    AI->>AI: Process with tools
    AI->>CVM: Response with tool calls
    CVM->>TR: executeTool(name, args)
    TR->>T: execute(arguments)
    T->>S: System operations
    S->>T: System data
    T->>TR: Tool result
    TR->>CVM: Formatted result
    CVM->>AI: sendMessage(with tool results)
    AI->>CVM: Final response
    CVM->>CV: Update UI
    CV->>U: Display answer
```

### Diagram 3: Data Flow Pattern (Slide 12)
**Unidirectional Data Flow**

```mermaid
graph LR
    UA[User Action] --> VM[ViewModel]
    VM --> S[Service]
    S --> T[Tool]
    T --> SYS[System]
    
    SYS --> DATA[Data]
    DATA --> RESULT[Result]
    RESULT --> SC[State Change]
    SC --> UI[UI Update]
    
    style UA fill:#e1f5fe
    style UI fill:#e8f5e8
    style VM fill:#fff3e0
    style S fill:#fff3e0
    style T fill:#fff3e0
    style SYS fill:#fce4ec
    style DATA fill:#fce4ec
    style RESULT fill:#fce4ec
    style SC fill:#fce4ec
```

### Diagram 4: Distributed System Architecture (Slide 18)
**Multi-Agent Fleet Management**

```mermaid
graph TB
    subgraph "Enterprise Fleet"
        E1[Endpoint 1<br/>macOS Agent]
        E2[Endpoint 2<br/>macOS Agent]
        E3[Endpoint N<br/>macOS Agent]
    end

    subgraph "Control Tower"
        CT[Control Tower Server]
        AI_CT[AI Coordination Agent]
        DB[(State Database)]
        ML[ML Model Registry]
    end

    subgraph "Admin Console"
        AC[Admin Dashboard]
        RG[Report Generator]
    end

    E1 -->|Telemetry Stream| CT
    E2 -->|Telemetry Stream| CT
    E3 -->|Telemetry Stream| CT

    CT -->|Remediation Commands| E1
    CT -->|Remediation Commands| E2
    CT -->|Remediation Commands| E3

    AI_CT -->|Query State| DB
    AI_CT -->|Load Models| ML

    CT -->|Aggregated Insights| AC
    RG -->|Generate Reports| AC

    E1 -.->|Agent-to-Agent| E2
    E2 -.->|Coordination| E3
```

### Diagram 5: Evolution Roadmap Timeline (Slide 17)
**4-Phase Development Plan**

```mermaid
gantt
    title Breadcrumbs Evolution Roadmap
    dateFormat  YYYY-MM-DD
    section Phase 1: POC
    Manual diagnostics           :done, p1, 2024-01-01, 2024-03-31
    4 diagnostic tools           :done, p1b, 2024-01-01, 2024-03-31
    REST API                     :done, p1c, 2024-01-01, 2024-03-31
    
    section Phase 2: Enhanced
    Remediation actions          :active, p2, 2024-04-01, 2024-09-30
    Risk assessment              :p2b, 2024-04-01, 2024-09-30
    WebSocket streaming          :p2c, 2024-04-01, 2024-09-30
    
    section Phase 3: Control Tower
    Fleet management             :p3, 2024-10-01, 2025-03-31
    Bidirectional comms          :p3b, 2024-10-01, 2025-03-31
    Admin dashboard              :p3c, 2024-10-01, 2025-03-31
    
    section Phase 4: Autonomous
    Predictive diagnostics       :p4, 2025-04-01, 2025-12-31
    Federated learning           :p4b, 2025-04-01, 2025-12-31
    Zero-touch resolution        :p4c, 2025-04-01, 2025-12-31
```

### Diagram 6: Security Architecture (Slide 6)
**Privacy-First Design**

```mermaid
graph TB
    subgraph "User Authentication"
        U[User]
        BI[Biometric Auth]
        KC[Keychain]
    end
    
    subgraph "API Security"
        API[OpenAI API]
        HTTPS[HTTPS/TLS]
        KEY[API Key]
    end
    
    subgraph "Local Security"
        SB[Sandbox]
        ENT[Entitlements]
        PERM[Permissions]
    end
    
    U --> BI
    BI --> KC
    KC --> KEY
    KEY --> HTTPS
    HTTPS --> API
    
    U --> SB
    SB --> ENT
    ENT --> PERM
    
    style U fill:#e1f5fe
    style BI fill:#e8f5e8
    style KC fill:#e8f5e8
    style API fill:#fff3e0
    style HTTPS fill:#fff3e0
    style KEY fill:#fff3e0
    style SB fill:#fce4ec
    style ENT fill:#fce4ec
    style PERM fill:#fce4ec
```

### Diagram 7: Use Case Flow - VPN Failure (Slide 13)
**Current POC Behavior**

```mermaid
flowchart TD
    A[User: "My VPN isn't working"] --> B[AI Assistant]
    B --> C[Uses VPNDetectorTool]
    C --> D[Tool Result:<br/>VPN Status: Not Connected<br/>Last Known: IKEv2, utun0<br/>Disconnected Since: 2:45 PM]
    D --> E[AI Response:<br/>Your VPN is disconnected.<br/>Try these steps:<br/>1. Check network<br/>2. Restart VPN<br/>3. Check credentials]
    
    style A fill:#e1f5fe
    style B fill:#fff3e0
    style C fill:#fff3e0
    style D fill:#fce4ec
    style E fill:#e8f5e8
```

### Diagram 8: API Evolution (Slide 19)
**REST → WebSocket → Agent Protocol**

```mermaid
graph LR
    subgraph "Phase 1: POC API"
        P1A[HTTP REST Endpoints]
        P1B[GET /health]
        P1C[POST /chat]
        P1D[Bearer token auth]
    end
    
    subgraph "Phase 2: Enhanced API"
        P2A[REST + WebSocket]
        P2B[Real-time streaming]
        P2C[Bidirectional comms]
        P2D[Event-driven updates]
    end
    
    subgraph "Phase 3-4: Vision API"
        P3A[Agent Protocol]
        P3B[Semantic messages]
        P3C[Multi-agent coord]
        P3D[Certificate auth]
    end
    
    subgraph "Phase 4+: Future API"
        P4A[Federated Learning]
        P4B[Model updates]
        P4C[Gradient sharing]
        P4D[Privacy-preserving]
    end
    
    P1A --> P2A
    P2A --> P3A
    P3A --> P4A
    
    style P1A fill:#e1f5fe
    style P2A fill:#fff3e0
    style P3A fill:#e8f5e8
    style P4A fill:#fce4ec
```

### Diagram 9: Comparison Table - Impact Analysis (Slide 20)
**POC vs Enhanced vs Autonomous**

```mermaid
graph TB
    subgraph "POC (Current)"
        P1A[User-initiated chat]
        P1B[AI analyzes on request]
        P1C[Manual user actions]
        P1D[None]
        P1E[Single endpoint]
        P1F[Minutes-hours]
    end
    
    subgraph "Enhanced (P2)"
        P2A[User + periodic checks]
        P2B[AI + offers actions]
        P2C[Semi-automated approval]
        P2D[Local history]
        P2E[Single endpoint]
        P2F[Seconds-minutes]
    end
    
    subgraph "Autonomous (P4)"
        P3A[Continuous predictive]
        P3B[AI predicts before failure]
        P3C[Fully autonomous]
        P3D[Federated fleet-wide]
        P3E[Multi-endpoint + tower]
        P3F[Zero predictive/seconds]
    end
    
    P1A -.-> P2A
    P2A -.-> P3A
    P1B -.-> P2B
    P2B -.-> P3B
    P1C -.-> P2C
    P2C -.-> P3C
    
    style P1A fill:#e1f5fe
    style P1B fill:#e1f5fe
    style P1C fill:#e1f5fe
    style P2A fill:#fff3e0
    style P2B fill:#fff3e0
    style P2C fill:#fff3e0
    style P3A fill:#e8f5e8
    style P3B fill:#e8f5e8
    style P3C fill:#e8f5e8
```

### Diagram 10: Technology Stack (Slide 11)
**Modern macOS Development**

```mermaid
graph TB
    subgraph "Core Technologies"
        SWIFT[Swift 5.9+<br/>Modern language features]
        SWIFTUI[SwiftUI<br/>Declarative UI framework]
        MACOS[macOS 15.0+<br/>Latest system APIs]
    end
    
    subgraph "AI & Networking"
        OPENAI[OpenAI API<br/>GPT + function calling]
        VAPOR[Vapor<br/>Web framework]
        ASYNC[Async/Await<br/>Concurrency patterns]
    end
    
    subgraph "System Integration"
        NETEXT[NetworkExtension<br/>VPN detection]
        SYSCONFIG[SystemConfiguration<br/>Network diagnostics]
        SECURITY[Security<br/>Keychain operations]
        LOCALAUTH[LocalAuthentication<br/>Biometric auth]
    end
    
    SWIFT --> OPENAI
    SWIFTUI --> VAPOR
    MACOS --> NETEXT
    
    OPENAI --> SECURITY
    VAPOR --> SYSCONFIG
    ASYNC --> LOCALAUTH
    
    style SWIFT fill:#e1f5fe
    style SWIFTUI fill:#e1f5fe
    style MACOS fill:#e1f5fe
    style OPENAI fill:#fff3e0
    style VAPOR fill:#fff3e0
    style ASYNC fill:#fff3e0
    style NETEXT fill:#e8f5e8
    style SYSCONFIG fill:#e8f5e8
    style SECURITY fill:#e8f5e8
    style LOCALAUTH fill:#e8f5e8
```

## Visual Design Notes for Canva

### Color Coding for Diagrams:
- **Blue (#1e3a8a)**: Primary components and headers
- **Purple (#7c3aed)**: AI/ML components and highlights
- **Green (#10b981)**: Success states and positive flows
- **Orange (#f59e0b)**: Warnings and attention items
- **Gray (#6b7280)**: Supporting elements and connections

### Icon Suggestions:
- **Gear**: System tools and configuration
- **Brain**: AI and machine learning
- **Network**: Communication and connectivity
- **Shield**: Security and protection
- **Database**: Data storage and management
- **Chart**: Analytics and monitoring
- **Clock**: Timeline and evolution
- **Arrow**: Flow and direction

### Layout Guidelines:
- Use consistent spacing (20px between elements)
- Align all boxes and text consistently
- Use rounded corners (8px radius) for modern look
- Add subtle shadows for depth
- Use connecting lines with arrow heads for flow direction
- Group related elements with background colors or borders

These diagrams can be easily recreated in Canva using the text-based layouts provided above, with the visual design guidelines for colors, icons, and layout principles.
