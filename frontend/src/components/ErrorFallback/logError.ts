import type { ErrorInfo } from "react";
import { logger } from "@/lib/logger";

export function logError(error: unknown, info: ErrorInfo) {
  const errorObj = error instanceof Error ? error : new Error(String(error));
  logger.error("React Error Boundary caught error", {
    message: errorObj.message,
    name: errorObj.name,
    stack: errorObj.stack,
    componentStack: info.componentStack,
  });
}
