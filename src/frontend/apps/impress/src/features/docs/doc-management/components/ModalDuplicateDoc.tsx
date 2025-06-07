import {
  Button,
  Modal,
  ModalSize,
  VariantType,
  useToastProvider,
} from '@openfun/cunningham-react';
import { t } from 'i18next';
import { usePathname } from 'next/navigation';
import { useRouter } from 'next/router';

import { Box, Text, TextErrors } from '@/components';

import { useDuplicateDoc } from '../api/useDuplicateDoc';
import { Doc } from '../types';

interface ModalDuplicateDocProps {
  onClose: () => void;
  doc: Doc;
}

export const ModalDuplicateDoc = ({ onClose, doc }: ModalDuplicateDocProps) => {
  const { toast } = useToastProvider();
  const { push } = useRouter();
  const pathname = usePathname();

  const {
    mutate: duplicateDoc,

    isError,
    error,
  } = useDuplicateDoc({
    onSuccess: () => {
      toast(t('The document has been duplicated.'), VariantType.SUCCESS, {
        duration: 4000,
      });
      if (pathname === '/') {
        onClose();
      } else {
        void push('/');
      }
    },
  });

  return (
    <Modal
      isOpen
      closeOnClickOutside
      onClose={() => onClose()}
      rightActions={
        <>
          <Button
            aria-label={t('Close the modal')}
            color="secondary"
            fullWidth
            onClick={() => onClose()}
          >
            {t('Cancel')}
          </Button>
          <Button
            aria-label={t('Confirm duplication')}
            color="primary"
            fullWidth
            onClick={() =>
              duplicateDoc({
                docId: doc.id,
              })
            }
          >
            {t('Duplicate')}
          </Button>
        </>
      }
      size={ModalSize.SMALL}
      title={
        <Text
          $size="h6"
          as="h6"
          $margin={{ all: '0' }}
          $align="flex-start"
          $variation="1000"
        >
          {t('Duplicate a doc')}
        </Text>
      }
    >
      <Box
        aria-label={t('Content modal to duplicate document')}
        className="--docs--modal-duplicate-doc"
      >
        {!isError && (
          <Text $size="sm" $variation="600">
            {t('Are you sure you want to duplicate this document ?')}
          </Text>
        )}

        {isError && <TextErrors causes={error.cause} />}
      </Box>
    </Modal>
  );
};
