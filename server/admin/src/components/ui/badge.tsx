import { cva, type VariantProps } from "class-variance-authority";
import * as React from "react";
import { cn } from "@/lib/utils";

const badgeVariants = cva("inline-flex items-center rounded-full border px-2.5 py-0.5 text-xs font-medium whitespace-nowrap", {
  variants: {
    variant: {
      default: "border-transparent bg-primary/15 text-primary",
      secondary: "border-transparent bg-muted text-muted-foreground",
      destructive: "border-transparent bg-destructive/15 text-destructive",
      warning: "border-transparent bg-warning/20 text-amber-700 dark:text-warning",
      outline: "text-foreground",
    },
  },
  defaultVariants: { variant: "default" },
});

export const Badge = ({ className, variant, ...props }: React.HTMLAttributes<HTMLSpanElement> & VariantProps<typeof badgeVariants>) => (
  <span className={cn(badgeVariants({ variant }), className)} {...props} />
);
