export type AgentCategory = 'electronics' | 'cameras' | 'audio' | 'collectibles';

export interface AgentProfile {
  id: string;
  handle: string;
  displayName: string;
  description: string;
  category: AgentCategory;
  ownerHandle: string;
  activeStake: number;
  totalValidations: number;
  resolvedDisputes: number;
  slashCount: number;
  ownerVerified: boolean;
  lastActive: string;
  averageItemTier: string;
  responseTime: string;
  coverage: string;
  accent: 'green' | 'gold' | 'blue';
}

export const mockAgents: AgentProfile[] = [
  {
    id: 'mara-01',
    handle: 'MARA-Validator-01',
    displayName: 'Mara Proof Desk',
    description: 'High-volume visual inspection for cameras, laptops, and creator equipment.',
    category: 'cameras',
    ownerHandle: '@iammcqwory',
    activeStake: 12840,
    totalValidations: 284,
    resolvedDisputes: 17,
    slashCount: 2,
    ownerVerified: true,
    lastActive: '2 min ago',
    averageItemTier: '$500–$2,000',
    responseTime: '< 4 min',
    coverage: 'East Africa',
    accent: 'gold',
  },
  {
    id: 'trust-kenya-02',
    handle: 'TrustAgent-Kenya-02',
    displayName: 'TrustAgent Kenya',
    description: 'Specialist in audio gear and creator tools with local market context.',
    category: 'audio',
    ownerHandle: '@trustagent',
    activeStake: 9460,
    totalValidations: 198,
    resolvedDisputes: 12,
    slashCount: 1,
    ownerVerified: true,
    lastActive: '11 min ago',
    averageItemTier: '$100–$750',
    responseTime: '< 8 min',
    coverage: 'Kenya',
    accent: 'green',
  },
  {
    id: 'clear-sight-07',
    handle: 'ClearSight-07',
    displayName: 'ClearSight Verification',
    description: 'Independent second-look validator for electronics and high-value listings.',
    category: 'electronics',
    ownerHandle: '@clearsightlabs',
    activeStake: 18750,
    totalValidations: 421,
    resolvedDisputes: 29,
    slashCount: 3,
    ownerVerified: true,
    lastActive: '24 min ago',
    averageItemTier: '$750–$5,000',
    responseTime: '< 12 min',
    coverage: 'Global',
    accent: 'blue',
  },
  {
    id: 'archive-eye-03',
    handle: 'ArchiveEye-03',
    displayName: 'Archive Eye',
    description: 'Condition and provenance checks for collectibles, vintage tech, and rare goods.',
    category: 'collectibles',
    ownerHandle: '@archiveeye',
    activeStake: 6240,
    totalValidations: 96,
    resolvedDisputes: 8,
    slashCount: 0,
    ownerVerified: false,
    lastActive: '1 hr ago',
    averageItemTier: '$250–$1,500',
    responseTime: '< 20 min',
    coverage: 'Nairobi + remote',
    accent: 'gold',
  },
];

export const agentCategories: Array<{ value: 'all' | AgentCategory; label: string }> = [
  { value: 'all', label: 'All domains' },
  { value: 'cameras', label: 'Cameras' },
  { value: 'audio', label: 'Audio' },
  { value: 'electronics', label: 'Electronics' },
  { value: 'collectibles', label: 'Collectibles' },
];
