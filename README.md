# Decentralized Asset Tracking Maintenance System

A comprehensive blockchain-based system for tracking, maintaining, and managing physical assets using Stacks blockchain and Clarity smart contracts.

## System Overview

This system provides a complete solution for asset lifecycle management through five interconnected smart contracts:

1. **Asset Coordinator Verification** - Validates and manages asset tracking coordinators
2. **Location Tracking** - Tracks real-time asset locations and movement history
3. **Maintenance Scheduling** - Schedules and manages maintenance activities
4. **Condition Monitoring** - Monitors asset health and performance metrics
5. **Lifecycle Management** - Manages complete asset lifecycle from creation to disposal

## Architecture

### Core Components

- **Coordinators**: Verified entities responsible for asset management
- **Assets**: Physical items being tracked with unique identifiers
- **Locations**: Geographic or facility-based positions
- **Maintenance Records**: Scheduled and completed maintenance activities
- **Condition Reports**: Health and performance monitoring data

### Data Flow

1. Coordinators are verified through the verification contract
2. Assets are registered and assigned to coordinators
3. Location updates are recorded with timestamps
4. Maintenance is scheduled based on conditions and time intervals
5. Condition monitoring triggers maintenance when thresholds are exceeded
6. Lifecycle events are tracked from creation to disposal

## Contract Details

### Asset Coordinator Verification (asset-coordinator.clar)
- Manages coordinator registration and verification
- Tracks coordinator permissions and status
- Handles coordinator role assignments

### Location Tracking (location-tracking.clar)
- Records asset location updates
- Maintains location history
- Validates location data integrity

### Maintenance Scheduling (maintenance-scheduling.clar)
- Schedules preventive maintenance
- Tracks maintenance completion
- Manages maintenance personnel assignments

### Condition Monitoring (condition-monitoring.clar)
- Records asset condition metrics
- Monitors performance thresholds
- Triggers maintenance alerts

### Lifecycle Management (lifecycle-management.clar)
- Manages asset creation and registration
- Tracks ownership transfers
- Handles asset retirement and disposal

## Getting Started

### Prerequisites
- Clarinet CLI installed
- Node.js and npm for testing
- Stacks wallet for deployment

### Installation

\`\`\`bash
git clone <repository-url>
cd asset-tracking-system
npm install
\`\`\`

### Testing

\`\`\`bash
npm test
\`\`\`

### Deployment

\`\`\`bash
clarinet deploy --testnet
\`\`\`

## Usage Examples

### Register a Coordinator
\`\`\`clarity
(contract-call? .asset-coordinator register-coordinator "maintenance-team-1" "Primary Maintenance Team")
\`\`\`

### Track Asset Location
\`\`\`clarity
(contract-call? .location-tracking update-location u1 "warehouse-a" u1234567890)
\`\`\`

### Schedule Maintenance
\`\`\`clarity
(contract-call? .maintenance-scheduling schedule-maintenance u1 "routine-inspection" u1234567890)
\`\`\`

### Record Condition Data
\`\`\`clarity
(contract-call? .condition-monitoring record-condition u1 u85 "temperature" u1234567890)
\`\`\`

## Error Codes

- ERR-NOT-AUTHORIZED (u100): Caller lacks required permissions
- ERR-INVALID-INPUT (u101): Invalid input parameters
- ERR-NOT-FOUND (u102): Requested resource not found
- ERR-ALREADY-EXISTS (u103): Resource already exists
- ERR-INVALID-STATUS (u104): Invalid status for operation

## Security Considerations

- All critical operations require coordinator verification
- Asset ownership is strictly enforced
- Location updates include timestamp validation
- Maintenance records are immutable once created
- Condition thresholds prevent unauthorized modifications

## Contributing

Please read the contributing guidelines and submit pull requests for any improvements.

## License

This project is licensed under the MIT License.
