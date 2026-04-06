export interface Listing {
  id: string;
  title: string;
  price: number;
  seller: string;
  category: 'camera' | 'lens' | 'audio' | 'lighting' | 'computer';
  imageUrl: string;
  description: string;
  condition: 'Excellent' | 'Very Good' | 'Good' | 'Fair';
  stakeRequired: number; // in USDC
  isStaked: boolean;
  validator?: string;
}

export const mockListings: Listing[] = [
  {
    id: '1',
    title: 'Sony A7III Body Only',
    price: 1200,
    seller: '0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb',
    category: 'camera',
    imageUrl: 'https://images.unsplash.com/photo-1606980604682-2d8b2a0b6d3f',
    description: '24.2MP full-frame mirrorless. 120k shutter count. Includes battery and charger.',
    condition: 'Very Good',
    stakeRequired: 420, // 35% of $1200
    isStaked: true,
    validator: 'MARA-Validator-01',
  },
  {
    id: '2',
    title: 'Canon EF 50mm f/1.8 STM',
    price: 85,
    seller: '0x8ba1f109551bD432803012645Ac136ddd64DBA72',
    category: 'lens',
    imageUrl: 'https://images.unsplash.com/photo-1606980604682-2d8b2a0b6d3f',
    description: 'The nifty fifty. Sharp portrait lens. Minor cosmetic wear.',
    condition: 'Good',
    stakeRequired: 17, // 20% stake for items under $100
    isStaked: false,
  },
  {
    id: '3',
    title: 'Rode VideoMic Pro+',
    price: 180,
    seller: '0xdD2FD4581271e230360230F9337D5c0430Bf44C0',
    category: 'audio',
    imageUrl: 'https://images.unsplash.com/photo-1590602847861-f357a9332bbc',
    description: 'On-camera shotgun mic with USB power. Perfect for video work.',
    condition: 'Excellent',
    stakeRequired: 63, // 35% of $180
    isStaked: true,
    validator: 'TrustAgent-Kenya-02',
  },
  {
    id: '4',
    title: 'Godox SL-60W LED Light',
    price: 140,
    seller: '0x71C7656EC7ab88b098defB751B7401B5f6d8976F',
    category: 'lighting',
    imageUrl: 'https://images.unsplash.com/photo-1478737270239-2f02b77fc618',
    description: 'Continuous LED video light. 60W output. Silent operation.',
    condition: 'Very Good',
    stakeRequired: 49, // 35% of $140
    isStaked: false,
  },
  {
    id: '5',
    title: 'MacBook Pro 14" M1 Pro (2021)',
    price: 1600,
    seller: '0x5aAeb6053F3E94C9b9A09f33669435E7Ef1BeAed',
    category: 'computer',
    imageUrl: 'https://images.unsplash.com/photo-1517336714731-489689fd1ca8',
    description: '16GB RAM, 512GB SSD. 87 battery cycles. AppleCare until 2025.',
    condition: 'Excellent',
    stakeRequired: 560, // 35% of $1600
    isStaked: true,
    validator: 'MARA-Validator-01',
  },
  {
    id: '6',
    title: 'Fujifilm X-T4 Body',
    price: 950,
    seller: '0xCD2a3d9F938E13CD947Ec05AbC7FE734Df8DD826',
    category: 'camera',
    imageUrl: 'https://images.unsplash.com/photo-1606980604682-2d8b2a0b6d3f',
    description: 'APS-C mirrorless with IBIS. Film simulation modes. 45k shutter count.',
    condition: 'Very Good',
    stakeRequired: 475, // 50% stake for $500-$1000 tier
    isStaked: false,
  },
  {
    id: '7',
    title: 'Sigma 18-35mm f/1.8 DC HSM (Canon)',
    price: 450,
    seller: '0x0bFfC6D1bFF91349c4c61F33Ba8B84F3e5D4B8Bf',
    category: 'lens',
    imageUrl: 'https://images.unsplash.com/photo-1606980604682-2d8b2a0b6d3f',
    description: 'The legendary zoom. Constant f/1.8 across range. Canon EF mount.',
    condition: 'Excellent',
    stakeRequired: 158, // 35% of $450
    isStaked: true,
    validator: 'TrustAgent-Kenya-02',
  },
  {
    id: '8',
    title: 'Zoom H6 Audio Recorder',
    price: 220,
    seller: '0x47E7c7E3f03e2E7cC7b54FFC7fF3f0F3f3f3f3f3',
    category: 'audio',
    imageUrl: 'https://images.unsplash.com/photo-1590602847861-f357a9332bbc',
    description: '6-track field recorder. XLR inputs. SD card included.',
    condition: 'Good',
    stakeRequired: 77, // 35% of $220
    isStaked: false,
  },
];
