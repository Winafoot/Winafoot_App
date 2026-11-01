import { cva, type VariantProps } from "class-variance-authority";
import * as React from "react";
import { cn } from "@/lib/utils";

const alertVariants = cva("rounded-lg border p-3 text-sm", {
  variants: {
    variant: {
      default: "bg-muted",
      destructive: "border-destructive/40 bg-destructive/10 text-destructive",
      success: "border-primary/40 bg-primary/10 text-primary",
      warning: "border-warning/50 bg-warning/15",
    },
  },
  defaultVariants: { variant: "default" },
});

export const Alert = ({ className, variant, ...props }: React.HTMLAttributes<HTMLDivElement> & VariantProps<typeof alertVariants>) => (
  <div role="alert" className={cn(alertVariants({ variant }), className)} {...props} />
);
