export interface DonateDetail {
  labelKey: string;
  value: string;
}

export interface DonateMethod {
  id: "bank" | "momo" | "paypal" | "usdt";
  titleKey: string;
  icon: string;
  details: DonateDetail[];
  noteKey?: string;
}

// Public payment instructions are kept here so the UI has one source of truth.
export const donateMethods: DonateMethod[] = [
  {
    id: "bank",
    titleKey: "donate.method.bank",
    icon: "/donate/bank-vietqr.svg",
    details: [
      { labelKey: "donate.bank", value: "MB Bank" },
      { labelKey: "donate.accountName", value: "MAI PHUOC TOAN" },
      { labelKey: "donate.accountNumber", value: "0090393476217" },
    ],
    noteKey: "donate.transferNote",
  },
  {
    id: "momo",
    titleKey: "donate.method.momo",
    icon: "/donate/momo.svg",
    details: [
      { labelKey: "donate.accountName", value: "MAI PHUOC TOAN" },
      { labelKey: "donate.phone", value: "0394576217" },
    ],
    noteKey: "donate.transferNote",
  },
  {
    id: "paypal",
    titleKey: "donate.method.paypal",
    icon: "/donate/paypal.svg",
    details: [{ labelKey: "donate.email", value: "niemtinchienthang9703@gmail.com" }],
  },
  {
    id: "usdt",
    titleKey: "donate.method.usdt",
    icon: "/donate/usdt.svg",
    details: [
      { labelKey: "donate.network", value: "ERC20" },
      { labelKey: "donate.wallet", value: "0xb7276e5bc853a46772f1b0a09b25cd5b2f096617" },
    ],
    noteKey: "donate.networkNote",
  },
];
