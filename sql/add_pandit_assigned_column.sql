-- Add pandit_assigned column to pandit_package_orders table
-- This migration adds the missing column that the application code expects

-- Add the pandit_assigned column to store the assigned pandit ID
ALTER TABLE public.pandit_package_orders 
ADD COLUMN IF NOT EXISTS pandit_assigned UUID REFERENCES public.pandits(id);

-- Add index for better query performance
CREATE INDEX IF NOT EXISTS idx_pandit_package_orders_pandit_assigned 
ON public.pandit_package_orders(pandit_assigned);

-- Add index for filtering by user_id and pandit_assigned together
CREATE INDEX IF NOT EXISTS idx_pandit_package_orders_user_pandit 
ON public.pandit_package_orders(user_id, pandit_assigned);

-- Add comment to document the column purpose
COMMENT ON COLUMN public.pandit_package_orders.pandit_assigned IS 'ID of the pandit assigned to fulfill this package order';
