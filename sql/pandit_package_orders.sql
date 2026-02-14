-- pandit_package_orders table
CREATE TABLE IF NOT EXISTS public.pandit_package_orders (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  package_id uuid NOT NULL REFERENCES public.pandit_packages(id) ON DELETE RESTRICT,
  amount numeric NOT NULL,
  currency text NOT NULL DEFAULT 'INR',
  status text NOT NULL DEFAULT 'created',
  razorpay_order_id text NOT NULL,
  razorpay_payment_id text,
  razorpay_signature text,
  failure_reason text,
  pandit_assigned uuid REFERENCES public.pandits(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- helpful indexes
CREATE INDEX IF NOT EXISTS idx_pandit_package_orders_user ON public.pandit_package_orders(user_id);
CREATE INDEX IF NOT EXISTS idx_pandit_package_orders_order ON public.pandit_package_orders(razorpay_order_id);
CREATE INDEX IF NOT EXISTS idx_pandit_package_orders_pandit_assigned ON public.pandit_package_orders(pandit_assigned);
CREATE INDEX IF NOT EXISTS idx_pandit_package_orders_user_pandit ON public.pandit_package_orders(user_id, pandit_assigned);

-- Add comment to document the pandit_assigned column
COMMENT ON COLUMN public.pandit_package_orders.pandit_assigned IS 'ID of the pandit assigned to fulfill this package order';


