import {
  UseMutationOptions,
  useMutation,
  useQueryClient,
} from '@tanstack/react-query';

import { APIError, errorCauses, fetchAPI } from '@/api';

import { KEY_LIST_DOC } from './useDocs';

interface DuplicateDocProps {
  docId: string;
}

export const duplicateDoc = async ({
  docId,
}: DuplicateDocProps): Promise<void> => {
  const response = await fetchAPI(`documents/${docId}/duplicate/`, {
    method: 'POST',
  });

  if (!response.ok) {
    throw new APIError(
      'Failed to duplicate the doc',
      await errorCauses(response),
    );
  }
};

type UseDuplicateDocOptions = UseMutationOptions<
  void,
  APIError,
  DuplicateDocProps
>;

export const useDuplicateDoc = (options?: UseDuplicateDocOptions) => {
  const queryClient = useQueryClient();
  return useMutation<void, APIError, DuplicateDocProps>({
    mutationFn: duplicateDoc,
    ...options,
    onSuccess: (data, variables, context) => {
      void queryClient.invalidateQueries({
        queryKey: [KEY_LIST_DOC],
      });
      if (options?.onSuccess) {
        options.onSuccess(data, variables, context);
      }
    },
    onError: (error, variables, context) => {
      if (options?.onError) {
        options.onError(error, variables, context);
      }
    },
  });
};
