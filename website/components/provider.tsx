'use client';
import SearchDialog from '@/components/search';
import { RootProvider } from 'fumadocs-ui/provider/next';
import { type ReactNode } from 'react';
import { MotionConfig } from 'motion/react';

export function Provider({ children }: { children: ReactNode }) {
  return <RootProvider search={{ SearchDialog }}><MotionConfig reducedMotion="user">{children}</MotionConfig></RootProvider>;
}
